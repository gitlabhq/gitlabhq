# frozen_string_literal: true

class Namespace < ApplicationRecord
  include CacheMarkdownField
  include Sortable
  include Gitlab::VisibilityLevel
  include Routable
  include AfterCommitQueue
  include Storage::LegacyNamespace
  include Gitlab::SQL::Pattern
  include FeatureGate
  include FromUnion
  include Gitlab::Utils::StrongMemoize

  # Prevent users from creating unreasonably deep level of nesting.
  # The number 20 was taken based on maximum nesting level of
  # Android repo (15) + some extra backup.
  NUMBER_OF_ANCESTORS_ALLOWED = 20

  cache_markdown_field :description, pipeline: :description

  has_many :projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :project_statistics

  has_many :runner_namespaces, inverse_of: :namespace, class_name: 'Ci::RunnerNamespace'
  has_many :runners, through: :runner_namespaces, source: :runner, class_name: 'Ci::Runner'

  # This should _not_ be `inverse_of: :namespace`, because that would also set
  # `user.namespace` when this user creates a group with themselves as `owner`.
  belongs_to :owner, class_name: "User"

  belongs_to :parent, class_name: "Namespace"
  has_many :children, class_name: "Namespace", foreign_key: :parent_id
  has_one :chat_team, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :root_storage_statistics, class_name: 'Namespace::RootStorageStatistics'
  has_one :aggregation_schedule, class_name: 'Namespace::AggregationSchedule'

  validates :owner, presence: true, unless: ->(n) { n.type == "Group" }
  validates :name,
    presence: true,
    length: { maximum: 255 }

  validates :description, length: { maximum: 255 }
  validates :path,
    presence: true,
    length: { maximum: 255 },
    namespace_path: true

  validates :max_artifacts_size, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  validate :nesting_level_allowed

  validates_associated :runners

  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :avatar_url, to: :owner, allow_nil: true

  after_commit :refresh_access_of_projects_invited_groups, on: :update, if: -> { previous_changes.key?('share_with_group_lock') }

  before_create :sync_share_with_group_lock_with_parent
  before_update :sync_share_with_group_lock_with_parent, if: :parent_changed?
  after_update :force_share_with_group_lock_on_descendants, if: -> { saved_change_to_share_with_group_lock? && share_with_group_lock? }

  # Legacy Storage specific hooks

  after_update :move_dir, if: :saved_change_to_path_or_parent?
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
        'COALESCE(SUM(ps.wiki_size), 0) AS wiki_size',
        'COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size',
        'COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size',
        'COALESCE(SUM(ps.packages_size), 0) AS packages_size'
      )
  end

  class << self
    def by_path(path)
      find_by('lower(path) = :value', value: path.downcase)
    end

    # Case insensitive search for namespace by path or name
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

    def find_by_pages_host(host)
      gitlab_host = "." + Settings.pages.host.downcase
      host = host.downcase
      return unless host.ends_with?(gitlab_host)

      name = host.delete_suffix(gitlab_host)
      Namespace.find_by_full_path(name)
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

  def first_project_with_container_registry_tags
    all_projects.find(&:has_container_registry_tags?)
  end

  def send_update_instructions
    projects.each do |project|
      project.send_move_instructions("#{full_path_before_last_save}/#{project.path}")
    end
  end

  def kind
    type == 'Group' ? 'group' : 'user'
  end

  def user?
    kind == 'user'
  end

  def find_fork_of(project)
    return unless project.fork_network

    if Gitlab::SafeRequestStore.active?
      forks_in_namespace = Gitlab::SafeRequestStore.fetch("namespaces:#{id}:forked_projects") do
        Hash.new do |found_forks, project|
          found_forks[project] = project.fork_network.find_forks_in(projects).first
        end
      end

      forks_in_namespace[project]
    else
      project.fork_network.find_forks_in(projects).first
    end
  end

  # any ancestor can disable emails for all descendants
  def emails_disabled?
    strong_memoize(:emails_disabled) do
      if parent_id
        self_and_ancestors.where(emails_disabled: true).exists?
      else
        !!emails_disabled
      end
    end
  end

  def lfs_enabled?
    # User namespace will always default to the global setting
    Gitlab.config.lfs.enabled
  end

  def shared_runners_enabled?
    projects.with_shared_runners.any?
  end

  # Returns all ancestors, self, and descendants of the current namespace.
  def self_and_hierarchy
    Gitlab::ObjectHierarchy
      .new(self.class.where(id: id))
      .all_objects
  end

  # Returns all the ancestors of the current namespaces.
  def ancestors
    return self.class.none unless parent_id

    Gitlab::ObjectHierarchy
      .new(self.class.where(id: parent_id))
      .base_and_ancestors
  end

  # returns all ancestors upto but excluding the given namespace
  # when no namespace is given, all ancestors upto the top are returned
  def ancestors_upto(top = nil, hierarchy_order: nil)
    Gitlab::ObjectHierarchy.new(self.class.where(id: id))
      .ancestors(upto: top, hierarchy_order: hierarchy_order)
  end

  def self_and_ancestors(hierarchy_order: nil)
    return self.class.where(id: id) unless parent_id

    Gitlab::ObjectHierarchy
      .new(self.class.where(id: id))
      .base_and_ancestors(hierarchy_order: hierarchy_order)
  end

  # Returns all the descendants of the current namespace.
  def descendants
    Gitlab::ObjectHierarchy
      .new(self.class.where(parent_id: id))
      .base_and_descendants
  end

  def self_and_descendants
    Gitlab::ObjectHierarchy
      .new(self.class.where(id: id))
      .base_and_descendants
  end

  def user_ids_for_project_authorizations
    [owner_id]
  end

  # Includes projects from this namespace and projects from all subgroups
  # that belongs to this namespace
  def all_projects
    Project.inside_path(full_path)
  end

  # Includes pipelines from this namespace and pipelines from all subgroups
  # that belongs to this namespace
  def all_pipelines
    Ci::Pipeline.where(project: all_projects)
  end

  def has_parent?
    parent_id.present? || parent.present?
  end

  def root_ancestor
    strong_memoize(:root_ancestor) do
      self_and_ancestors.reorder(nil).find_by(parent_id: nil)
    end
  end

  def subgroup?
    has_parent?
  end

  # Overridden on EE module
  def multiple_issue_boards_available?
    false
  end

  # Overridden in EE::Namespace
  def feature_available?(_feature)
    false
  end

  def full_path_before_last_save
    if parent_id_before_last_save.nil?
      path_before_last_save
    else
      previous_parent = Group.find_by(id: parent_id_before_last_save)
      previous_parent.full_path + '/' + path_before_last_save
    end
  end

  def refresh_project_authorizations
    owner.refresh_authorized_projects
  end

  def auto_devops_enabled?
    first_auto_devops_config[:status]
  end

  def first_auto_devops_config
    return { scope: :group, status: auto_devops_enabled } unless auto_devops_enabled.nil?

    strong_memoize(:first_auto_devops_config) do
      if has_parent?
        parent.first_auto_devops_config
      else
        { scope: :instance, status: Gitlab::CurrentSettings.auto_devops_enabled? }
      end
    end
  end

  def aggregation_scheduled?
    aggregation_schedule.present?
  end

  def pages_virtual_domain
    Pages::VirtualDomain.new(all_projects_with_pages, trim_prefix: full_path)
  end

  def closest_setting(name)
    self_and_ancestors(hierarchy_order: :asc)
      .find { |n| !n.read_attribute(name).nil? }
      .try(name)
  end

  private

  def all_projects_with_pages
    if all_projects.pages_metadata_not_migrated.exists?
      Gitlab::BackgroundMigration::MigratePagesMetadata.new.perform_on_relation(
        all_projects.pages_metadata_not_migrated
      )
    end

    all_projects.with_pages_deployed
  end

  def parent_changed?
    parent_id_changed?
  end

  def saved_change_to_parent?
    saved_change_to_parent_id?
  end

  def saved_change_to_path_or_parent?
    saved_change_to_path? || saved_change_to_parent_id?
  end

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
    # We can't use `descendants.update_all` since Rails will throw away the WITH
    # RECURSIVE statement. We also can't use WHERE EXISTS since we can't use
    # different table aliases, hence we're just using WHERE IN. Since we have a
    # maximum of 20 nested groups this should be fine.
    Namespace.where(id: descendants.select(:id))
      .update_all(share_with_group_lock: true)
  end

  def write_projects_repository_config
    all_projects.find_each do |project|
      project.write_repository_config
      project.track_project_repository
    end
  end
end

Namespace.prepend_if_ee('EE::Namespace')
