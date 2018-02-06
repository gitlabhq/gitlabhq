class Namespace < ActiveRecord::Base
  include CacheMarkdownField
  include Sortable
  include Gitlab::ShellAdapter
  include Gitlab::CurrentSettings
  include Gitlab::VisibilityLevel
  include Routable
  include AfterCommitQueue
  include Storage::LegacyNamespace
  include Gitlab::SQL::Pattern
  include IgnorableColumn

  ignore_column :deleted_at

  # Prevent users from creating unreasonably deep level of nesting.
  # The number 20 was taken based on maximum nesting level of
  # Android repo (15) + some extra backup.
  NUMBER_OF_ANCESTORS_ALLOWED = 20

  cache_markdown_field :description, pipeline: :description

  has_many :projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :project_statistics

  # This should _not_ be `inverse_of: :namespace`, because that would also set
  # `user.namespace` when this user creates a group with themselves as `owner`.
  belongs_to :owner, class_name: "User"

  belongs_to :parent, class_name: "Namespace"
  has_many :children, class_name: "Namespace", foreign_key: :parent_id
  has_one :chat_team, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

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
    namespace_path: true

  validate :nesting_level_allowed
  validate :allowed_path_by_redirects

  delegate :name, to: :owner, allow_nil: true, prefix: true

  after_commit :refresh_access_of_projects_invited_groups, on: :update, if: -> { previous_changes.key?('share_with_group_lock') }

  before_create :sync_share_with_group_lock_with_parent
  before_update :sync_share_with_group_lock_with_parent, if: :parent_changed?
  after_update :force_share_with_group_lock_on_descendants, if: -> { share_with_group_lock_changed? && share_with_group_lock? }

  # Legacy Storage specific hooks

  after_update :move_dir, if: :path_changed?
  before_destroy(prepend: true) { prepare_for_destroy }
  after_destroy :rm_dir

  scope :for_user, -> { where('type IS NULL') }

  scope :with_statistics, -> do
    joins('LEFT JOIN project_statistics ps ON ps.namespace_id = namespaces.id')
      .group('namespaces.id')
      .select(
        'namespaces.*',
        'COALESCE(SUM(ps.storage_size), 0) AS storage_size',
        'COALESCE(SUM(ps.repository_size), 0) AS repository_size',
        'COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size',
        'COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size'
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
      fuzzy_search(query, [:name, :path])
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

  def visibility_level_field
    :visibility_level
  end

  def to_param
    full_path
  end

  def human_name
    owner_name
  end

  def any_project_has_container_registry_tags?
    all_projects.any?(&:has_container_registry_tags?)
  end

  def send_update_instructions
    projects.each do |project|
      project.send_move_instructions("#{full_path_was}/#{project.path}")
    end
  end

  def kind
    type == 'Group' ? 'group' : 'user'
  end

  def find_fork_of(project)
    return nil unless project.fork_network

    if RequestStore.active?
      forks_in_namespace = RequestStore.fetch("namespaces:#{id}:forked_projects") do
        Hash.new do |found_forks, project|
          found_forks[project] = project.fork_network.find_forks_in(projects).first
        end
      end

      forks_in_namespace[project]
    else
      project.fork_network.find_forks_in(projects).first
    end
  end

  def lfs_enabled?
    # User namespace will always default to the global setting
    Gitlab.config.lfs.enabled
  end

  def shared_runners_enabled?
    projects.with_shared_runners.any?
  end

  # Returns all the ancestors of the current namespaces.
  def ancestors
    return self.class.none unless parent_id

    Gitlab::GroupHierarchy
      .new(self.class.where(id: parent_id))
      .base_and_ancestors
  end

  # returns all ancestors upto but excluding the the given namespace
  # when no namespace is given, all ancestors upto the top are returned
  def ancestors_upto(top = nil)
    Gitlab::GroupHierarchy.new(self.class.where(id: id))
      .ancestors(upto: top)
  end

  def self_and_ancestors
    return self.class.where(id: id) unless parent_id

    Gitlab::GroupHierarchy
      .new(self.class.where(id: id))
      .base_and_ancestors
  end

  # Returns all the descendants of the current namespace.
  def descendants
    Gitlab::GroupHierarchy
      .new(self.class.where(parent_id: id))
      .base_and_descendants
  end

  def self_and_descendants
    Gitlab::GroupHierarchy
      .new(self.class.where(id: id))
      .base_and_descendants
  end

  def user_ids_for_project_authorizations
    [owner_id]
  end

  def parent_changed?
    parent_id_changed?
  end

  # Includes projects from this namespace and projects from all subgroups
  # that belongs to this namespace
  def all_projects
    Project.inside_path(full_path)
  end

  def has_parent?
    parent.present?
  end

  def subgroup?
    has_parent?
  end

  private

  def refresh_access_of_projects_invited_groups
    Group
      .joins(project_group_links: :project)
      .where(projects: { namespace_id: id })
      .find_each(&:refresh_members_authorized_projects)
  end

  def nesting_level_allowed
    if ancestors.count > Group::NUMBER_OF_ANCESTORS_ALLOWED
      errors.add(:parent_id, "has too deep level of nesting")
    end
  end

  def sync_share_with_group_lock_with_parent
    if parent&.share_with_group_lock?
      self.share_with_group_lock = true
    end
  end

  def force_share_with_group_lock_on_descendants
    return unless Group.supports_nested_groups?

    # We can't use `descendants.update_all` since Rails will throw away the WITH
    # RECURSIVE statement. We also can't use WHERE EXISTS since we can't use
    # different table aliases, hence we're just using WHERE IN. Since we have a
    # maximum of 20 nested groups this should be fine.
    Namespace.where(id: descendants.select(:id))
      .update_all(share_with_group_lock: true)
  end

  def allowed_path_by_redirects
    return if path.nil?

    errors.add(:path, "#{path} has been taken before. Please use another one") if namespace_previously_created_with_same_path?
  end

  def namespace_previously_created_with_same_path?
    RedirectRoute.permanent.exists?(path: path)
  end

  def write_projects_repository_config
    all_projects.find_each do |project|
      project.expires_full_path_cache # we need to clear cache to validate renames correctly
      project.write_repository_config
    end
  end
end
