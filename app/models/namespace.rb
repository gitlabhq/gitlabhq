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
  include IgnorableColumns
  include Namespaces::Traversal::Recursive
  include Namespaces::Traversal::Linear
  include EachBatch

  ignore_column :delayed_project_removal, remove_with: '14.1', remove_after: '2021-05-22'

  # Prevent users from creating unreasonably deep level of nesting.
  # The number 20 was taken based on maximum nesting level of
  # Android repo (15) + some extra backup.
  NUMBER_OF_ANCESTORS_ALLOWED = 20

  SHARED_RUNNERS_SETTINGS = %w[disabled_and_unoverridable disabled_with_override enabled].freeze

  cache_markdown_field :description, pipeline: :description

  has_many :projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :project_statistics
  has_one :namespace_settings, inverse_of: :namespace, class_name: 'NamespaceSetting', autosave: true

  has_many :runner_namespaces, inverse_of: :namespace, class_name: 'Ci::RunnerNamespace'
  has_many :runners, through: :runner_namespaces, source: :runner, class_name: 'Ci::Runner'
  has_one :onboarding_progress

  # This should _not_ be `inverse_of: :namespace`, because that would also set
  # `user.namespace` when this user creates a group with themselves as `owner`.
  belongs_to :owner, class_name: "User"

  belongs_to :parent, class_name: "Namespace"
  has_many :children, class_name: "Namespace", foreign_key: :parent_id
  has_many :custom_emoji, inverse_of: :namespace
  has_one :chat_team, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :root_storage_statistics, class_name: 'Namespace::RootStorageStatistics'
  has_one :aggregation_schedule, class_name: 'Namespace::AggregationSchedule'
  has_one :package_setting_relation, inverse_of: :namespace, class_name: 'PackageSetting'

  has_one :admin_note, inverse_of: :namespace
  accepts_nested_attributes_for :admin_note, update_only: true

  validates :owner, presence: true, unless: ->(n) { n.type == "Group" }
  validates :name,
    presence: true,
    length: { maximum: 255 }

  validates :description, length: { maximum: 255 }
  validates :path,
    presence: true,
    length: { maximum: 255 },
    namespace_path: true

  # Introduce minimal path length of 2 characters.
  # Allow change of other attributes without forcing users to
  # rename their user or group. At the same time prevent changing
  # the path without complying with new 2 chars requirement.
  # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/225214
  validates :path, length: { minimum: 2 }, if: :path_changed?

  validates :max_artifacts_size, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  validate :validate_parent_type, if: -> { Feature.enabled?(:validate_namespace_parent_type) }
  validate :nesting_level_allowed
  validate :changing_shared_runners_enabled_is_allowed
  validate :changing_allow_descendants_override_disabled_shared_runners_is_allowed

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
  after_commit :expire_child_caches, on: :update, if: -> {
    Feature.enabled?(:cached_route_lookups, self, type: :ops, default_enabled: :yaml) &&
      saved_change_to_name? || saved_change_to_path? || saved_change_to_parent_id?
  }

  scope :for_user, -> { where(type: nil) }
  scope :sort_by_type, -> { order(Gitlab::Database.nulls_first_order(:type)) }
  scope :include_route, -> { includes(:route) }
  scope :by_parent, -> (parent) { where(parent_id: parent) }
  scope :filter_by_path, -> (query) { where('lower(path) = :query', query: query.downcase) }

  scope :with_statistics, -> do
    joins('LEFT JOIN project_statistics ps ON ps.namespace_id = namespaces.id')
      .group('namespaces.id')
      .select(
        'namespaces.*',
        'COALESCE(SUM(ps.storage_size), 0) AS storage_size',
        'COALESCE(SUM(ps.repository_size), 0) AS repository_size',
        'COALESCE(SUM(ps.wiki_size), 0) AS wiki_size',
        'COALESCE(SUM(ps.snippets_size), 0) AS snippets_size',
        'COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size',
        'COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size',
        'COALESCE(SUM(ps.packages_size), 0) AS packages_size',
        'COALESCE(SUM(ps.uploads_size), 0) AS uploads_size'
      )
  end

  scope :sorted_by_similarity_and_parent_id_desc, -> (search) do
    order_expression = Gitlab::Database::SimilarityScore.build_expression(search: search, rules: [
      { column: arel_table["path"], multiplier: 1 },
      { column: arel_table["name"], multiplier: 0.7 }
    ])
    reorder(order_expression.desc, Namespace.arel_table['parent_id'].desc.nulls_last, Namespace.arel_table['id'].desc)
  end

  # Make sure that the name is same as strong_memoize name in root_ancestor
  # method
  attr_writer :root_ancestor, :emails_disabled_memoized

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
    # This method uses ILIKE on PostgreSQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search(query, include_parents: false)
      if include_parents
        where(id: Route.for_routable_type(Namespace.name).fuzzy_search(query, [Route.arel_table[:path], Route.arel_table[:name]]).select(:source_id))
      else
        fuzzy_search(query, [:path, :name])
      end
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

    def clean_name(value)
      value.scan(Gitlab::Regex.group_name_regex_chars).join(' ')
    end

    def find_by_pages_host(host)
      gitlab_host = "." + Settings.pages.host.downcase
      host = host.downcase
      return unless host.ends_with?(gitlab_host)

      name = host.delete_suffix(gitlab_host)
      Namespace.where(parent_id: nil).by_path(name)
    end

    def top_most
      where(parent_id: nil)
    end
  end

  def package_settings
    package_setting_relation || build_package_setting_relation
  end

  def default_branch_protection
    super || Gitlab::CurrentSettings.default_branch_protection
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
    all_projects.includes(:container_repositories).any?(&:has_container_registry_tags?)
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

  def group?
    type == 'Group'
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
    strong_memoize(:emails_disabled_memoized) do
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

  def any_project_with_shared_runners_enabled?
    projects.with_shared_runners.any?
  end

  def user_ids_for_project_authorizations
    [owner_id]
  end

  # Includes projects from this namespace and projects from all subgroups
  # that belongs to this namespace
  def all_projects
    if Feature.enabled?(:recursive_approach_for_all_projects, default_enabled: :yaml)
      namespace = user? ? self : self_and_descendant_ids
      Project.where(namespace: namespace)
    else
      Project.inside_path(full_path)
    end
  end

  def has_parent?
    parent_id.present? || parent.present?
  end

  def subgroup?
    has_parent?
  end

  # Overridden on EE module
  def multiple_issue_boards_available?
    false
  end

  # Deprecated, use #licensed_feature_available? instead. Remove once Namespace#feature_available? isn't used anymore.
  def feature_available?(feature)
    licensed_feature_available?(feature)
  end

  # Overridden in EE::Namespace
  def licensed_feature_available?(_feature)
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
    Pages::VirtualDomain.new(
      all_projects_with_pages.includes(:route, :project_feature, pages_metadatum: :pages_deployment),
      trim_prefix: full_path
    )
  end

  def any_project_with_pages_deployed?
    all_projects.with_pages_deployed.any?
  end

  def closest_setting(name)
    self_and_ancestors(hierarchy_order: :asc)
      .find { |n| !n.read_attribute(name).nil? }
      .try(name)
  end

  def actual_plan
    Plan.default
  end

  def paid?
    root? && actual_plan.paid?
  end

  def actual_limits
    # We default to PlanLimits.new otherwise a lot of specs would fail
    # On production each plan should already have associated limits record
    # https://gitlab.com/gitlab-org/gitlab/issues/36037
    actual_plan.actual_limits
  end

  def actual_plan_name
    actual_plan.name
  end

  def changing_shared_runners_enabled_is_allowed
    return unless new_record? || changes.has_key?(:shared_runners_enabled)

    if shared_runners_enabled && has_parent? && parent.shared_runners_setting == 'disabled_and_unoverridable'
      errors.add(:shared_runners_enabled, _('cannot be enabled because parent group has shared Runners disabled'))
    end
  end

  def changing_allow_descendants_override_disabled_shared_runners_is_allowed
    return unless new_record? || changes.has_key?(:allow_descendants_override_disabled_shared_runners)

    if shared_runners_enabled && !new_record?
      errors.add(:allow_descendants_override_disabled_shared_runners, _('cannot be changed if shared runners are enabled'))
    end

    if allow_descendants_override_disabled_shared_runners && has_parent? && parent.shared_runners_setting == 'disabled_and_unoverridable'
      errors.add(:allow_descendants_override_disabled_shared_runners, _('cannot be enabled because parent group does not allow it'))
    end
  end

  def shared_runners_setting
    if shared_runners_enabled
      'enabled'
    else
      if allow_descendants_override_disabled_shared_runners
        'disabled_with_override'
      else
        'disabled_and_unoverridable'
      end
    end
  end

  def shared_runners_setting_higher_than?(other_setting)
    if other_setting == 'enabled'
      false
    elsif other_setting == 'disabled_with_override'
      shared_runners_setting == 'enabled'
    elsif other_setting == 'disabled_and_unoverridable'
      shared_runners_setting == 'enabled' || shared_runners_setting == 'disabled_with_override'
    else
      raise ArgumentError
    end
  end

  def root?
    !has_parent?
  end

  def recent?
    created_at >= 90.days.ago
  end

  def issue_repositioning_disabled?
    Feature.enabled?(:block_issue_repositioning, self, type: :ops, default_enabled: :yaml)
  end

  private

  def expire_child_caches
    Namespace.where(id: descendants).each_batch do |namespaces|
      namespaces.touch_all
    end

    all_projects.each_batch do |projects|
      projects.touch_all
    end
  end

  def all_projects_with_pages
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
      errors.add(:parent_id, 'has too deep level of nesting')
    end
  end

  def validate_parent_type
    return unless has_parent?

    if user?
      errors.add(:parent_id, 'a user namespace cannot have a parent')
    elsif group?
      errors.add(:parent_id, 'a group cannot have a user namespace as its parent') if parent.user?
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

Namespace.prepend_mod_with('Namespace')
