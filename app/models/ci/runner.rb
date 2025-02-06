# frozen_string_literal: true

module Ci
  class Runner < Ci::ApplicationRecord
    prepend Ci::BulkInsertableTags
    include Gitlab::SQL::Pattern
    include RedisCacheable
    include ChronicDurationAttribute
    include FromUnion
    include TokenAuthenticatable
    include FeatureGate
    include Gitlab::Utils::StrongMemoize
    include TaggableQueries
    include Presentable
    include EachBatch
    include Ci::HasRunnerStatus
    include Ci::Taggable

    extend ::Gitlab::Utils::Override

    add_authentication_token_field :token,
      encrypted: :optional,
      expires_at: :compute_token_expiration,
      format_with_prefix: :prefix_for_new_and_legacy_runner

    enum access_level: {
      not_protected: 0,
      ref_protected: 1
    }

    enum runner_type: {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }

    enum creation_state: {
      started: 0,
      finished: 100
    }, _suffix: true

    enum registration_type: {
      registration_token: 0,
      authenticated_user: 1
    }, _suffix: true

    # Prefix assigned to runners created from the UI, instead of registered via the command line
    CREATED_RUNNER_TOKEN_PREFIX = 'glrt-'

    RUNNER_SHORT_SHA_LENGTH = 8

    # This `ONLINE_CONTACT_TIMEOUT` needs to be larger than
    #   `RUNNER_QUEUE_EXPIRY_TIME+UPDATE_CONTACT_COLUMN_EVERY`
    #
    ONLINE_CONTACT_TIMEOUT = 2.hours

    # The `RUNNER_QUEUE_EXPIRY_TIME` indicates the longest interval that
    #   Runner request needs to be refreshed by Rails instead of being handled
    #   by Workhorse
    RUNNER_QUEUE_EXPIRY_TIME = 1.hour

    # The `UPDATE_CONTACT_COLUMN_EVERY` defines how often the Runner DB entry can be updated
    UPDATE_CONTACT_COLUMN_EVERY = ((40.minutes)..(55.minutes))

    # The `STALE_TIMEOUT` constant defines the how far past the last contact or creation date a runner will be considered stale
    STALE_TIMEOUT = 7.days

    # Only allow authentication token to be visible for a short while
    REGISTRATION_AVAILABILITY_TIME = 1.hour

    AVAILABLE_TYPES_LEGACY = %w[specific shared].freeze
    AVAILABLE_TYPES = runner_types.keys.freeze
    DEPRECATED_STATUSES = %w[active paused].freeze # TODO: Remove in REST v5. Relevant issue: https://gitlab.com/gitlab-org/gitlab/-/issues/344648
    AVAILABLE_STATUSES = %w[online offline never_contacted stale].freeze
    AVAILABLE_STATUSES_INCL_DEPRECATED = (DEPRECATED_STATUSES + AVAILABLE_STATUSES).freeze
    AVAILABLE_SCOPES = (AVAILABLE_TYPES_LEGACY + AVAILABLE_TYPES + AVAILABLE_STATUSES_INCL_DEPRECATED).freeze

    FORM_EDITABLE = %i[description tag_list active run_untagged locked access_level maximum_timeout_human_readable].freeze
    MINUTES_COST_FACTOR_FIELDS = %i[public_projects_minutes_cost_factor private_projects_minutes_cost_factor].freeze

    TAG_LIST_MAX_LENGTH = 50

    has_many :runner_managers, inverse_of: :runner
    has_many :builds
    has_many :running_builds, inverse_of: :runner
    has_many :runner_projects, inverse_of: :runner, autosave: true, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
    has_many :projects, through: :runner_projects, disable_joins: true
    has_many :runner_namespaces, inverse_of: :runner, autosave: true
    has_many :groups, through: :runner_namespaces, disable_joins: true
    has_many :taggings, class_name: 'Ci::RunnerTagging', inverse_of: :runner
    has_many :tags, class_name: 'Ci::Tag', through: :taggings, source: :tag

    # currently we have only 1 namespace assigned, but order is here for consistency
    has_one :owner_runner_namespace, -> { order(:id) }, class_name: 'Ci::RunnerNamespace'

    has_one :last_build, -> { order('id DESC') }, class_name: 'Ci::Build'

    belongs_to :creator, class_name: 'User', optional: true

    before_save :ensure_token
    after_destroy :cleanup_runner_queue

    scope :active, ->(value = true) { where(active: value) }
    scope :paused, -> { active(false) }
    scope :recent, -> do
      timestamp = stale_deadline

      where(arel_table[:created_at].gt(timestamp).or(arel_table[:contacted_at].gt(timestamp)))
    end
    scope :stale, -> do
      stale_timestamp = stale_deadline

      where(created_at: ..stale_timestamp)
        .and(never_contacted.or(where(contacted_at: ..stale_timestamp)))
    end
    scope :ordered, -> { order(id: :desc) }

    scope :with_recent_runner_queue, -> { where(arel_table[:contacted_at].gt(recent_queue_deadline)) }
    scope :with_executing_builds, -> do
      where_exists(
        ::Ci::Build.executing
          .where("#{::Ci::Build.quoted_table_name}.runner_id = #{quoted_table_name}.id")
      )
    end

    # BACKWARD COMPATIBILITY: There are needed to maintain compatibility with `AVAILABLE_SCOPES` used by `lib/api/runners.rb`
    scope :deprecated_shared, -> { instance_type }
    scope :deprecated_specific, -> { project_type.or(group_type) }

    scope :belonging_to_project, ->(project_id) {
      joins(:runner_projects).where(ci_runner_projects: { project_id: project_id })
    }

    scope :belonging_to_group, ->(group_id) {
      joins(:runner_namespaces).where(ci_runner_namespaces: { namespace_id: group_id })
    }

    scope :created_by_admins, -> { with_creator_id(User.admins.ids) }

    scope :with_creator_id, ->(value) { where(creator_id: value) }
    scope :with_sharding_key, ->(value) { where(sharding_key_id: value) }

    scope :belonging_to_group_or_project_descendants, ->(group_id) {
      group_ids = Ci::NamespaceMirror.by_group_and_descendants(group_id).select(:namespace_id)
      project_ids = Ci::ProjectMirror.by_namespace_id(group_ids).select(:project_id)

      group_runners = belonging_to_group(group_ids)
      project_runners = belonging_to_project(project_ids).distinct

      from_union(
        [group_runners, project_runners],
        remove_duplicates: false
      )
    }

    scope :belonging_to_group_and_ancestors, ->(group_id) {
      group_self_and_ancestors_ids = ::Group.find_by(id: group_id)&.self_and_ancestor_ids

      belonging_to_group(group_self_and_ancestors_ids)
    }

    scope :belonging_to_parent_groups_of_project, ->(project_id) {
      raise ArgumentError, "only 1 project_id allowed for performance reasons" unless project_id.is_a?(Integer)

      project_groups = ::Group.joins(:projects).where(projects: { id: project_id })

      belonging_to_group(project_groups.self_and_ancestors.pluck(:id))
    }

    scope :owned_or_instance_wide, ->(project_id) do
      project = project_id.respond_to?(:shared_runners) ? project_id : Project.find(project_id)

      from_union(
        [
          belonging_to_project(project_id),
          project.group_runners_enabled? ? belonging_to_parent_groups_of_project(project_id) : nil,
          project.shared_runners
        ].compact,
        remove_duplicates: false
      )
    end

    scope :group_or_instance_wide, ->(group) do
      from_union(
        [
          belonging_to_group_and_ancestors(group.id),
          group.shared_runners
        ],
        remove_duplicates: false
      )
    end

    scope :usable_from_scope, ->(group) do
      from_union(
        [
          belonging_to_group(group.ancestor_ids),
          belonging_to_group_or_project_descendants(group.id),
          group.shared_runners
        ],
        remove_duplicates: false
      )
    end

    scope :assignable_for, ->(project) do
      # FIXME: That `to_sql` is needed to workaround a weird Rails bug.
      #        Without that, placeholders would miss one and couldn't match.
      #
      # We use "unscoped" here so that any current Ci::Runner filters don't
      # apply to the inner query, which is not necessary.
      exclude_runners = unscoped { project.runners.select(:id) }.to_sql

      where(locked: false)
        .where.not("ci_runners.id IN (#{exclude_runners})")
        .project_type
    end

    scope :order_contacted_at_asc, -> { order(contacted_at: :asc) }
    scope :order_contacted_at_desc, -> { order(contacted_at: :desc) }
    scope :order_created_at_asc, -> { order(created_at: :asc) }
    scope :order_created_at_desc, -> { order(created_at: :desc) }
    scope :order_token_expires_at_asc, -> { order(token_expires_at: :asc) }
    scope :order_token_expires_at_desc, -> { order(token_expires_at: :desc) }

    scope :with_tags, -> { preload(:tags) }
    scope :with_creator, -> { preload(:creator) }

    validate :tag_constraints
    validates :sharding_key_id, presence: true, unless: :instance_type?
    validates :name, length: { maximum: 256 }, if: :name_changed?
    validates :description, length: { maximum: 1024 }, if: :description_changed?
    validates :access_level, presence: true
    validates :runner_type, presence: true
    validates :registration_type, presence: true

    validate :no_projects, unless: :project_type?
    validate :no_sharding_key_id, if: :instance_type?
    validate :no_groups, unless: :group_type?
    validate :any_project, if: :project_type?
    validate :exactly_one_group, if: :group_type?
    validate :no_allowed_plan_ids, unless: :instance_type?

    scope :with_version_prefix, ->(value) { joins(:runner_managers).merge(RunnerManager.with_version_prefix(value)) }
    scope :with_runner_type, ->(runner_type) do
      return all if AVAILABLE_TYPES.exclude?(runner_type.to_s)

      where(runner_type: runner_type)
    end

    cached_attr_reader :contacted_at

    chronic_duration_attr :maximum_timeout_human_readable, :maximum_timeout,
      error_message: 'Maximum job timeout has a value which could not be accepted'

    validates :maximum_timeout, allow_nil: true,
      numericality: { greater_than_or_equal_to: 600, message: 'needs to be at least 10 minutes' }

    validates :public_projects_minutes_cost_factor, :private_projects_minutes_cost_factor,
      allow_nil: false,
      numericality: { greater_than_or_equal_to: 0.0, message: 'needs to be non-negative' }

    validates :maintenance_note, length: { maximum: 1024 }

    alias_attribute :maintenance_note, :maintainer_note # NOTE: Need to keep until REST v5 is implemented

    # Searches for runners matching the given query.
    #
    # This method uses ILIKE on PostgreSQL for the description field and performs a full match on tokens.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def self.search(query)
      where(token: query).or(fuzzy_search(query, [:description]))
    end

    def self.online_contact_time_deadline
      ONLINE_CONTACT_TIMEOUT.ago
    end

    def self.stale_deadline
      STALE_TIMEOUT.ago
    end

    def self.recent_queue_deadline
      # we add queue expiry + online
      # - contacted_at can be updated at any time within this interval
      #   we have always accurate `contacted_at` but it is stored in Redis
      #   and not persisted in database
      (ONLINE_CONTACT_TIMEOUT + RUNNER_QUEUE_EXPIRY_TIME).ago
    end

    def self.order_by(order)
      case order
      when 'contacted_asc'
        order_contacted_at_asc
      when 'contacted_desc'
        order_contacted_at_desc
      when 'created_at_asc'
        order_created_at_asc
      when 'token_expires_at_asc'
        order_token_expires_at_asc
      when 'token_expires_at_desc'
        order_token_expires_at_desc
      else
        order_created_at_desc
      end
    end

    def self.runner_matchers
      unique_params = [
        :runner_type,
        :public_projects_minutes_cost_factor,
        :private_projects_minutes_cost_factor,
        :run_untagged,
        :access_level,
        Arel.sql("(#{arel_tag_names_array.to_sql})"),
        :allowed_plan_ids
      ]

      group(*unique_params).pluck('array_agg(ci_runners.id)', *unique_params).map do |values|
        Gitlab::Ci::Matching::RunnerMatcher.new({
          runner_ids: values[0],
          runner_type: values[1],
          public_projects_minutes_cost_factor: values[2],
          private_projects_minutes_cost_factor: values[3],
          run_untagged: values[4],
          access_level: values[5],
          tag_list: values[6],
          allowed_plan_ids: values[7]
        })
      end
    end

    # TODO: Remove once https://gitlab.com/gitlab-org/gitlab/-/issues/516929 is closed.
    def self.sharded_table_proxy_model
      @sharded_table_proxy_class ||= Class.new(self) do
        self.table_name = :ci_runners_e59bb2812d
        self.primary_key = :id
      end
    end

    def self.taggings_join_model
      ::Ci::RunnerTagging
    end

    def runner_matcher
      Gitlab::Ci::Matching::RunnerMatcher.new({
        runner_ids: [id],
        runner_type: runner_type,
        public_projects_minutes_cost_factor: public_projects_minutes_cost_factor,
        private_projects_minutes_cost_factor: private_projects_minutes_cost_factor,
        run_untagged: run_untagged,
        access_level: access_level,
        tag_list: tag_list,
        allowed_plan_ids: allowed_plan_ids
      })
    end
    strong_memoize_attr :runner_matcher

    def assign_to(project, current_user = nil)
      if instance_type?
        raise ArgumentError, 'Transitioning an instance runner to a project runner is not supported'
      elsif group_type?
        raise ArgumentError, 'Transitioning a group runner to a project runner is not supported'
      end

      begin
        transaction do
          if ::Project.id_in(sharding_key_id).empty?
            self.clear_memoization(:owner)
            self.sharding_key_id = fallback_owner_project&.id || project.id
          end

          self.runner_projects << ::Ci::RunnerProject.new(project: project, runner: self)
          self.save!
        end
      rescue ActiveRecord::RecordInvalid => e
        self.errors.add(:assign_to, e.message)
        false
      end
    end

    def display_name
      return short_sha if description.blank?

      description
    end

    # DEPRECATED
    # TODO Remove in v5 in favor of `status` for REST calls, see https://gitlab.com/gitlab-org/gitlab/-/issues/344648
    def deprecated_rest_status
      return :stale if stale?

      if contacted_at.nil?
        :never_contacted
      elsif active?
        online? ? :online : :offline
      else
        :paused
      end
    end

    def owner
      case runner_type
      when 'instance_type'
        ::User.find_by_id(creator_id)
      when 'group_type'
        ::Group.find_by_id(sharding_key_id)
      when 'project_type'
        owner_project = ::Project.find_by_id(sharding_key_id)

        owner_project || fallback_owner_project
      end
    end
    strong_memoize_attr :owner

    def belongs_to_one_project?
      runner_projects.one?
    end

    def belongs_to_more_than_one_project?
      runner_projects.many?
    end

    def match_build_if_online?(build)
      active? && online? && matches_build?(build)
    end

    def only_for?(project)
      runner_projects.where.not(project_id: project.id).empty?
    end

    def short_sha
      return unless token

      # We want to show the first characters of the hash, so we need to bypass any fixed components of the token,
      # such as CREATED_RUNNER_TOKEN_PREFIX or partition_id_prefix_in_16_bit_encode
      partition_prefix = partition_id_prefix_in_16_bit_encode
      start_index = authenticated_user_registration_type? ? CREATED_RUNNER_TOKEN_PREFIX.length : 0
      start_index += partition_prefix.length if token[start_index..].start_with?(partition_prefix)
      token[start_index..start_index + RUNNER_SHORT_SHA_LENGTH - 1]
    end

    def has_tags?
      tag_list.any?
    end

    # TODO: Remove once https://gitlab.com/gitlab-org/gitlab/-/issues/516929 is closed.
    def ensure_partitioned_runner_record_exists
      self.class.sharded_table_proxy_model.insert_all(
        [attributes.except('tag_list')], unique_by: [:id, :runner_type],
        returning: false, record_timestamps: false
      )
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new
        .append(key: 'CI_RUNNER_ID', value: id.to_s)
        .append(key: 'CI_RUNNER_DESCRIPTION', value: description)
        .append(key: 'CI_RUNNER_TAGS', value: tag_list.to_a.to_s)
    end

    def tick_runner_queue
      ##
      # We only stick a runner to primary database to be able to detect the
      # replication lag in `EE::Ci::RegisterJobService#execute`. The
      # intention here is not to execute `Ci::RegisterJobService#execute` on
      # the primary database.
      #
      ::Ci::Runner.sticking.stick(:runner, id)

      SecureRandom.hex.tap do |new_update|
        ::Gitlab::Workhorse.set_key_and_notify(runner_queue_key, new_update,
          expire: RUNNER_QUEUE_EXPIRY_TIME, overwrite: true)
      end
    end

    def ensure_runner_queue_value
      new_value = SecureRandom.hex
      ::Gitlab::Workhorse.set_key_and_notify(runner_queue_key, new_value,
        expire: RUNNER_QUEUE_EXPIRY_TIME, overwrite: false)
    end

    def runner_queue_value_latest?(value)
      ensure_runner_queue_value == value if value.present?
    end

    def heartbeat
      ##
      # We can safely ignore writes performed by a runner heartbeat. We do
      # not want to upgrade database connection proxy to use the primary
      # database after heartbeat write happens.
      #
      ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).without_sticky_writes do
        values = { contacted_at: Time.current, creation_state: :finished }

        merge_cache_attributes(values)

        # We save data without validation, it will always change due to `contacted_at`
        update_columns(values) if persist_cached_data?
      end
    end

    def clear_heartbeat
      cleared_attributes = { contacted_at: nil }

      merge_cache_attributes(cleared_attributes)
      update_columns(cleared_attributes)
    end

    def pick_build!(build)
      tick_runner_queue if matches_build?(build)
    end

    def matches_build?(build)
      runner_matcher.matches?(build.build_matcher)
    end

    def uncached_contacted_at
      read_attribute(:contacted_at)
    end

    def namespace_ids
      runner_namespaces.pluck(:namespace_id).compact
    end
    strong_memoize_attr :namespace_ids

    def compute_token_expiration
      case runner_type
      when 'instance_type'
        compute_token_expiration_instance
      when 'group_type'
        compute_token_expiration_group
      when 'project_type'
        compute_token_expiration_project
      end
    end

    def ensure_manager(system_xid)
      # rubocop: disable Performance/ActiveRecordSubtransactionMethods -- This is used only in API endpoints outside of transactions
      RunnerManager.safe_find_or_create_by!(runner_id: id, system_xid: system_xid.to_s) do |m|
        # Avoid inserting partitioned runner managers that refer to a missing ci_runners partitioned record, since
        # the backfill is not yet finalized.
        ensure_partitioned_runner_record_exists if Feature.disabled?(:reject_orphaned_runners, Feature.current_request)

        m.runner_type = runner_type
        m.sharding_key_id = sharding_key_id
      end
      # rubocop: enable Performance/ActiveRecordSubtransactionMethods
    end

    def registration_available?
      authenticated_user_registration_type? &&
        created_at > REGISTRATION_AVAILABILITY_TIME.ago &&
        !runner_managers.any?
    end

    def gitlab_hosted?
      Gitlab.com? && instance_type?
    end

    private

    scope :with_upgrade_status, ->(upgrade_status) do
      joins(:runner_managers).merge(RunnerManager.with_upgrade_status(upgrade_status))
    end

    def fallback_owner_project
      # NOTE: when a project is deleted, the respective ci_runner_projects records are not immediately
      # deleted by the LFK, so we might find join records that point to a still-existing project
      project_ids = runner_projects.order(:id).pluck(:project_id)
      projects_added_to_runner_asc = Arel.sql("array_position(ARRAY[#{project_ids.join(',')}]::bigint[], id)")
      Project.order(projects_added_to_runner_asc).find_by_id(project_ids)
    end

    def compute_token_expiration_instance
      return unless expiration_interval = Gitlab::CurrentSettings.runner_token_expiration_interval

      expiration_interval.seconds.from_now
    end

    def compute_token_expiration_group
      ::Group.id_in(runner_namespaces.map(&:namespace_id))
        .map(&:effective_runner_token_expiration_interval)
        .compact.min&.from_now
    end

    def compute_token_expiration_project
      Project.id_in(runner_projects.map(&:project_id))
        .map(&:effective_runner_token_expiration_interval)
        .compact.min&.from_now
    end

    def cleanup_runner_queue
      ::Gitlab::Workhorse.cleanup_key(runner_queue_key)
    end

    def runner_queue_key
      "runner:build_queue:#{self.token}"
    end

    def persist_cached_data?
      # Use a random threshold to prevent beating DB updates.
      contacted_at_max_age = Random.rand(UPDATE_CONTACT_COLUMN_EVERY)

      real_contacted_at = read_attribute(:contacted_at)
      real_contacted_at.nil? ||
        (Time.current - real_contacted_at) >= contacted_at_max_age
    end

    def tag_constraints
      unless has_tags? || run_untagged?
        errors.add(:tags_list,
          'can not be empty when runner is not allowed to pick untagged jobs')
      end

      if tag_list_changed? && tag_list.count > TAG_LIST_MAX_LENGTH
        errors.add(:tags_list,
          "Too many tags specified. Please limit the number of tags to #{TAG_LIST_MAX_LENGTH}")
      end
    end

    def no_sharding_key_id
      errors.add(:runner, 'cannot have sharding_key_id assigned') if sharding_key_id
    end

    def no_projects
      errors.add(:runner, 'cannot have projects assigned') if runner_projects.any?
    end

    def no_groups
      errors.add(:runner, 'cannot have groups assigned') if runner_namespaces.any?
    end

    def any_project
      errors.add(:runner, 'needs to be assigned to at least one project') unless runner_projects.any?
    end

    def exactly_one_group
      errors.add(:runner, 'needs to be assigned to exactly one group') unless runner_namespaces.size == 1
    end

    def no_allowed_plan_ids
      errors.add(:runner, 'cannot have allowed plans assigned') unless allowed_plan_ids.empty?
    end

    def partition_id_prefix_in_16_bit_encode
      # Prefix with t1 / t2 / t3 (`t` as in runner type, to allow us to easily detect how a token got prefixed).
      # This is needed in order to ensure that tokens have unique values across partitions
      # in the new ci_runners_e59bb2812d partitioned table.
      "t#{self.class.runner_types[runner_type].to_s(16)}_"
    end

    def prefix_for_new_and_legacy_runner
      return partition_id_prefix_in_16_bit_encode if registration_token_registration_type?

      "#{CREATED_RUNNER_TOKEN_PREFIX}#{partition_id_prefix_in_16_bit_encode}"
    end
  end
end

Ci::Runner.prepend_mod_with('Ci::Runner')
