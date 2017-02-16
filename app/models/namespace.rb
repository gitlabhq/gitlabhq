class Namespace < ActiveRecord::Base
  acts_as_paranoid

  prepend EE::Namespace
  include CacheMarkdownField
  include Sortable
  include Gitlab::ShellAdapter
  include Gitlab::CurrentSettings
  include Routable

  # Prevent users from creating unreasonably deep level of nesting.
  # The number 20 was taken based on maximum nesting level of
  # Android repo (15) + some extra backup.
  NUMBER_OF_ANCESTORS_ALLOWED = 20

  cache_markdown_field :description, pipeline: :description

  has_many :projects, dependent: :destroy
  has_many :project_statistics
  belongs_to :owner, class_name: "User"

  belongs_to :parent, class_name: "Namespace"
  has_many :children, class_name: "Namespace", foreign_key: :parent_id

  validates :owner, presence: true, unless: ->(n) { n.type == "Group" }
  validates :name,
    presence: true,
    uniqueness: { scope: :parent_id },
    length: { maximum: 255 },
    namespace_name: true

  validates :description, length: { maximum: 255 }
  validates :path,
    presence: true,
    length: { maximum: 255 },
    namespace: true

  validate :nesting_level_allowed

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_update :move_dir, if: :path_changed?
  after_commit :refresh_access_of_projects_invited_groups, on: :update, if: -> { previous_changes.key?('share_with_group_lock') }

  # Save the storage paths before the projects are destroyed to use them on after destroy
  before_destroy(prepend: true) { prepare_for_destroy }
  after_destroy :rm_dir

  scope :root, -> { where('type IS NULL') }

  scope :with_statistics, -> do
    joins('LEFT JOIN project_statistics ps ON ps.namespace_id = namespaces.id')
      .group('namespaces.id')
      .select(
        'namespaces.*',
        'COALESCE(SUM(ps.storage_size), 0) AS storage_size',
        'COALESCE(SUM(ps.repository_size), 0) AS repository_size',
        'COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size',
        'COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size',
      )
  end

  class << self
    def by_path(path)
      find_by('lower(path) = :value', value: path.downcase)
    end

    # Case insensetive search for namespace by path or name
    def find_by_path_or_name(path)
      find_by("lower(path) = :path OR lower(name) = :path", path: path.downcase)
    end

    # Searches for namespaces matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation
    def search(query)
      t = arel_table
      pattern = "%#{query}%"

      where(t[:name].matches(pattern).or(t[:path].matches(pattern)))
    end

    def clean_path(path)
      path = path.dup
      # Get the email username by removing everything after an `@` sign.
      path.gsub!(/@.*\z/,                "")
      # Remove everything that's not in the list of allowed characters.
      path.gsub!(/[^a-zA-Z0-9_\-\.]/,    "")
      # Remove trailing violations ('.atom', '.git', or '.')
      path.gsub!(/(\.atom|\.git|\.)*\z/, "")
      # Remove leading violations ('-')
      path.gsub!(/\A\-+/,                "")

      # Users with the great usernames of "." or ".." would end up with a blank username.
      # Work around that by setting their username to "blank", followed by a counter.
      path = "blank" if path.blank?

      uniquify = Uniquify.new
      uniquify.string(path) { |s| Namespace.find_by_path_or_name(s) }
    end
  end

  def to_param
    full_path
  end

  def human_name
    owner_name
  end

  def move_dir
    if any_project_has_container_registry_tags?
      raise Gitlab::UpdatePathError.new('Namespace cannot be moved, because at least one project has tags in container registry')
    end

    # Move the namespace directory in all storages paths used by member projects
    repository_storage_paths.each do |repository_storage_path|
      # Ensure old directory exists before moving it
      gitlab_shell.add_namespace(repository_storage_path, path_was)

      unless gitlab_shell.mv_namespace(repository_storage_path, path_was, path)
        Rails.logger.error "Exception moving path #{repository_storage_path} from #{path_was} to #{path}"

        # if we cannot move namespace directory we should rollback
        # db changes in order to prevent out of sync between db and fs
        raise Gitlab::UpdatePathError.new('namespace directory cannot be moved')
      end
    end

    Gitlab::UploadsTransfer.new.rename_namespace(path_was, path)
    Gitlab::PagesTransfer.new.rename_namespace(path_was, path)

    remove_exports!

    # If repositories moved successfully we need to
    # send update instructions to users.
    # However we cannot allow rollback since we moved namespace dir
    # So we basically we mute exceptions in next actions
    begin
      send_update_instructions
    rescue
      # Returning false does not rollback after_* transaction but gives
      # us information about failing some of tasks
      false
    end
  end

  def any_project_has_container_registry_tags?
    projects.any?(&:has_container_registry_tags?)
  end

  def send_update_instructions
    projects.each do |project|
      project.send_move_instructions("#{path_was}/#{project.path}")
    end
  end

  def kind
    type == 'Group' ? 'group' : 'user'
  end

  def find_fork_of(project)
    projects.joins(:forked_project_link).find_by('forked_project_links.forked_from_project_id = ?', project.id)
  end

  def lfs_enabled?
    # User namespace will always default to the global setting
    Gitlab.config.lfs.enabled
  end

  def actual_size_limit
    current_application_settings.repository_size_limit
  end

  def shared_runners_enabled?
    projects.with_shared_runners.any?
  end

  # Scopes the model on ancestors of the record
  def ancestors
    if parent_id
      path = route ? route.path : full_path
      paths = []

      until path.blank?
        path = path.rpartition('/').first
        paths << path
      end

      self.class.joins(:route).where('routes.path IN (?)', paths).reorder('routes.path ASC')
    else
      self.class.none
    end
  end

  # Scopes the model on direct and indirect children of the record
  def descendants
    self.class.joins(:route).where('routes.path LIKE ?', "#{route.path}/%").reorder('routes.path ASC')
  end

  def user_ids_for_project_authorizations
    [owner_id]
  end

  def parent_changed?
    parent_id_changed?
  end

  def prepare_for_destroy
    old_repository_storage_paths
  end

  def old_repository_storage_paths
    @old_repository_storage_paths ||= repository_storage_paths
  end

  private

  def repository_storage_paths
    # We need to get the storage paths for all the projects, even the ones that are
    # pending delete. Unscoping also get rids of the default order, which causes
    # problems with SELECT DISTINCT.
    Project.unscoped do
      projects.select('distinct(repository_storage)').to_a.map(&:repository_storage_path)
    end
  end

  def rm_dir
    # Remove the namespace directory in all storages paths used by member projects
    old_repository_storage_paths.each do |repository_storage_path|
      # Move namespace directory into trash.
      # We will remove it later async
      new_path = "#{path}+#{id}+deleted"

      if gitlab_shell.mv_namespace(repository_storage_path, path, new_path)
        message = "Namespace directory \"#{path}\" moved to \"#{new_path}\""
        Gitlab::AppLogger.info message

        # Remove namespace directroy async with delay so
        # GitLab has time to remove all projects first
        GitlabShellWorker.perform_in(5.minutes, :rm_namespace, repository_storage_path, new_path)
      end
    end

    remove_exports!
  end

  def refresh_access_of_projects_invited_groups
    Group.
      joins(project_group_links: :project).
      where(projects: { namespace_id: id }).
      find_each(&:refresh_members_authorized_projects)
  end

  def remove_exports!
    Gitlab::Popen.popen(%W(find #{export_path} -not -path #{export_path} -delete))
  end

  def export_path
    File.join(Gitlab::ImportExport.storage_path, full_path_was)
  end

  def full_path_was
    if parent
      parent.full_path + '/' + path_was
    else
      path_was
    end
  end

  def nesting_level_allowed
    if ancestors.count > Group::NUMBER_OF_ANCESTORS_ALLOWED
      errors.add(:parent_id, "has too deep level of nesting")
    end
  end
end
