module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Project` model
  module Project
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Cache::RequestCache
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      include Elastic::ProjectsSearch
      include EE::DeploymentPlatform
      include EachBatch

      before_save :set_override_pull_mirror_available, unless: -> { ::Gitlab::CurrentSettings.mirror_available }
      before_save :set_next_execution_timestamp_to_now, if: ->(project) { project.mirror? && project.mirror_changed? && project.import_state }

      after_update :remove_mirror_repository_reference,
        if: ->(project) { project.mirror? && project.import_url_updated? }

      belongs_to :mirror_user, foreign_key: 'mirror_user_id', class_name: 'User'

      has_one :repository_state, class_name: 'ProjectRepositoryState', inverse_of: :project
      has_one :project_registry, class_name: 'Geo::ProjectRegistry', inverse_of: :project
      has_one :push_rule, ->(project) { project&.feature_available?(:push_rules) ? all : none }
      has_one :index_status
      has_one :jenkins_service
      has_one :jenkins_deprecated_service
      has_one :github_service

      has_many :approvers, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :audit_events, as: :entity
      has_many :path_locks
      has_many :vulnerability_feedback
      has_many :protected_environments
      has_many :software_license_policies, inverse_of: :project, class_name: 'SoftwareLicensePolicy'
      accepts_nested_attributes_for :software_license_policies, allow_destroy: true
      has_many :packages, class_name: 'Packages::Package'

      has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_project_id

      has_many :source_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :project_id

      has_many :prometheus_alerts, inverse_of: :project

      scope :with_shared_runners_limit_enabled, -> { with_shared_runners.non_public_only }

      scope :mirror, -> { where(mirror: true) }

      scope :inner_joins_import_state, -> { joins("INNER JOIN project_mirror_data import_state ON import_state.project_id = projects.id") }

      scope :mirrors_to_sync, ->(freeze_at) do
        mirror
          .inner_joins_import_state
          .where.not(import_state: { status: [:scheduled, :started] })
          .where("import_state.next_execution_timestamp <= ?", freeze_at)
          .where("import_state.retry_count <= ?", ::Gitlab::Mirror::MAX_RETRY)
      end

      scope :with_wiki_enabled,   -> { with_feature_enabled(:wiki) }

      scope :verified_repos, -> { joins(:repository_state).merge(ProjectRepositoryState.verified_repos) }
      scope :verified_wikis, -> { joins(:repository_state).merge(ProjectRepositoryState.verified_wikis) }
      scope :verification_failed_repos, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_repos) }
      scope :verification_failed_wikis, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_wikis) }

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :statistics, allow_nil: true

      delegate :actual_shared_runners_minutes_limit,
        :shared_runners_minutes_used?, to: :shared_runners_limit_namespace

      validates :repository_size_limit,
        numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

      validates :approvals_before_merge, numericality: true, allow_blank: true

      with_options if: :mirror? do
        validates :import_url, presence: true
        validates :mirror_user, presence: true
      end

      default_value_for :packages_enabled, true
    end

    class_methods do
      def search_by_visibility(level)
        where(visibility_level: ::Gitlab::VisibilityLevel.string_options[level])
      end

      def with_slack_application_disabled
        joins('LEFT JOIN services ON services.project_id = projects.id AND services.type = \'GitlabSlackApplicationService\' AND services.active IS true')
          .where('services.id IS NULL')
      end
    end

    def security_reports_feature_available?
      feature_available?(:sast) ||
        feature_available?(:dependency_scanning) ||
        feature_available?(:sast_container) ||
        feature_available?(:dast)
    end

    def latest_pipeline_with_security_reports
      pipelines.newest_first(default_branch).with_security_reports.first
    end

    def environments_for_scope(scope)
      quoted_scope = ::Gitlab::SQL::Glob.q(scope)

      environments.where("name LIKE (#{::Gitlab::SQL::Glob.to_like(quoted_scope)})") # rubocop:disable GitlabSecurity/SqlInjection
    end

    def ensure_external_webhook_token
      return if external_webhook_token.present?

      self.external_webhook_token = Devise.friendly_token
    end

    def shared_runners_limit_namespace
      if Feature.enabled?(:shared_runner_minutes_on_root_namespace)
        root_namespace
      else
        namespace
      end
    end

    def mirror
      super && feature_available?(:repository_mirrors) && pull_mirror_available?
    end
    alias_method :mirror?, :mirror

    def mirror_updated?
      mirror? && self.mirror_last_update_at
    end

    def mirror_waiting_duration
      return unless mirror?

      (import_state.last_update_started_at.to_i -
        import_state.last_update_scheduled_at.to_i).seconds
    end

    def mirror_update_duration
      return unless mirror?

      (mirror_last_update_at.to_i -
        import_state.last_update_started_at.to_i).seconds
    end

    def mirror_with_content?
      mirror? && !empty_repo?
    end

    def import_state_args
      super.merge(last_update_at: self[:mirror_last_update_at],
                  last_successful_update_at: self[:mirror_last_successful_update_at])
    end

    def mirror_last_update_at=(new_value)
      ensure_import_state

      import_state&.last_update_at = new_value
    end

    def mirror_last_update_at
      ensure_import_state

      import_state&.last_update_at
    end

    def mirror_last_successful_update_at=(new_value)
      ensure_import_state

      import_state&.last_successful_update_at = new_value
    end

    def mirror_last_successful_update_at
      ensure_import_state

      import_state&.last_successful_update_at
    end

    override :import_in_progress?
    def import_in_progress?
      # If we're importing while we do have a repository, we're simply updating the mirror.
      super && !mirror_with_content?
    end

    def mirror_about_to_update?
      return false unless mirror_with_content?
      return false if mirror_hard_failed?
      return false if updating_mirror?

      self.import_state.next_execution_timestamp <= Time.now
    end

    def updating_mirror?
      (import_scheduled? || import_started?) && mirror_with_content?
    end

    def mirror_last_update_status
      return unless mirror_updated?

      if self.mirror_last_update_at == self.mirror_last_successful_update_at
        :success
      else
        :failed
      end
    end

    def mirror_last_update_succeeded?
      mirror_last_update_status == :success
    end

    def mirror_last_update_failed?
      mirror_last_update_status == :failed
    end

    def mirror_ever_updated_successfully?
      mirror_updated? && self.mirror_last_successful_update_at
    end

    def mirror_hard_failed?
      self.import_state.retry_limit_exceeded?
    end

    def fetch_mirror
      return unless mirror?

      # Only send the password if it's needed
      url =
        if import_data&.password_auth?
          import_url
        else
          username_only_import_url
        end

      repository.fetch_upstream(url)
    end

    def can_override_approvers?
      !disable_overriding_approvers_per_merge_request?
    end

    def shared_runners_available?
      super && !shared_runners_limit_namespace.shared_runners_minutes_used?
    end

    def shared_runners_minutes_limit_enabled?
      !public? && shared_runners_enabled? &&
        shared_runners_limit_namespace.shared_runners_minutes_limit_enabled?
    end

    def feature_available?(feature, user = nil)
      if ProjectFeature::FEATURES.include?(feature)
        super
      else
        licensed_feature_available?(feature)
      end
    end

    override :multiple_issue_boards_available?
    def multiple_issue_boards_available?
      feature_available?(:multiple_project_issue_boards)
    end

    def service_desk_enabled
      ::EE::Gitlab::ServiceDesk.enabled?(project: self) && super
    end
    alias_method :service_desk_enabled?, :service_desk_enabled

    def service_desk_address
      return nil unless service_desk_enabled?

      config = ::Gitlab.config.incoming_email
      wildcard = ::Gitlab::IncomingEmail::WILDCARD_PLACEHOLDER

      config.address&.gsub(wildcard, full_path)
    end

    def force_import_job!
      return if mirror_about_to_update? || updating_mirror?

      import_state = self.import_state

      import_state.set_next_execution_to_now
      import_state.reset_retry_count if import_state.retry_limit_exceeded?

      import_state.save!

      UpdateAllMirrorsWorker.perform_async
    end

    override :add_import_job
    def add_import_job
      return if gitlab_custom_project_template_import?

      if import? && !repository_exists?
        super
      elsif mirror?
        ::Gitlab::Metrics.add_event(:mirrors_scheduled)
        job_id = RepositoryUpdateMirrorWorker.perform_async(self.id)

        log_import_activity(job_id, type: :mirror)

        job_id
      end
    end

    def secret_variables_for(ref:, environment: nil)
      return super.where(environment_scope: '*') unless
        environment && feature_available?(:variable_environment_scope)

      super.on_environment(environment)
    end

    def execute_hooks(data, hooks_scope = :push_hooks)
      super

      if group && feature_available?(:group_webhooks)
        run_after_commit_or_now do
          group.hooks.hooks_for(hooks_scope).each do |hook|
            hook.async_execute(data, hooks_scope.to_s)
          end
        end
      end
    end

    # No need to have a Kerberos Web url. Kerberos URL will be used only to
    # clone
    def kerberos_url_to_repo
      "#{::Gitlab.config.build_gitlab_kerberos_url + ::Gitlab::Routing.url_helpers.project_path(self)}.git"
    end

    def group_ldap_synced?
      if group
        group.ldap_synced?
      else
        false
      end
    end

    def reference_issue_tracker?
      default_issues_tracker? || jira_tracker_active?
    end

    def approvals_before_merge
      return 0 unless feature_available?(:merge_request_approvers)

      super
    end

    def reset_approvals_on_push
      super && feature_available?(:merge_request_approvers)
    end
    alias_method :reset_approvals_on_push?, :reset_approvals_on_push

    def approver_ids=(value)
      ::Gitlab::Utils.ensure_array_from_string(value).each do |user_id|
        approvers.find_or_create_by(user_id: user_id, target_id: id)
      end
    end

    def approver_group_ids=(value)
      ::Gitlab::Utils.ensure_array_from_string(value).each do |group_id|
        approver_groups.find_or_initialize_by(group_id: group_id, target_id: id)
      end
    end

    def find_path_lock(path, exact_match: false, downstream: false)
      path_lock_finder = strong_memoize(:path_lock_finder) do
        ::Gitlab::PathLocksFinder.new(self)
      end

      path_lock_finder.find(path, exact_match: exact_match, downstream: downstream)
    end

    def import_url_updated?
      # check if import_url has been updated and it's not just the first assignment
      import_url_changed? && changes['import_url'].first
    end

    def remove_mirror_repository_reference
      run_after_commit do
        repository.async_remove_remote(::Repository::MIRROR_REMOTE)
      end
    end

    def username_only_import_url
      bare_url = read_attribute(:import_url)
      return bare_url unless ::Gitlab::UrlSanitizer.valid?(bare_url)

      ::Gitlab::UrlSanitizer.new(bare_url, credentials: { user: import_data&.user }).full_url
    end

    def username_only_import_url=(value)
      unless ::Gitlab::UrlSanitizer.valid?(value)
        self.import_url = value
        self.import_data&.user = nil
        value
      end

      url = ::Gitlab::UrlSanitizer.new(value)
      creds = url.credentials.slice(:user)

      write_attribute(:import_url, url.sanitized_url)
      create_or_update_import_data(credentials: creds)

      username_only_import_url
    end

    def change_repository_storage(new_repository_storage_key)
      return if repository_read_only?
      return if repository_storage == new_repository_storage_key

      raise ArgumentError unless ::Gitlab.config.repositories.storages.keys.include?(new_repository_storage_key)

      run_after_commit { ProjectUpdateRepositoryStorageWorker.perform_async(id, new_repository_storage_key) }
      self.repository_read_only = true
    end

    def repository_and_lfs_size
      statistics.total_repository_size
    end

    def above_size_limit?
      return false unless size_limit_enabled?

      repository_and_lfs_size > actual_size_limit
    end

    def size_to_remove
      repository_and_lfs_size - actual_size_limit
    end

    def actual_size_limit
      return namespace.actual_size_limit if repository_size_limit.nil?

      repository_size_limit
    end

    def size_limit_enabled?
      return false unless License.feature_available?(:repository_size_limit)

      actual_size_limit != 0
    end

    def changes_will_exceed_size_limit?(size_in_bytes)
      size_limit_enabled? &&
        (size_in_bytes > actual_size_limit ||
         size_in_bytes + repository_and_lfs_size > actual_size_limit)
    end

    def remove_import_data
      super unless mirror?
    end

    def merge_requests_ff_only_enabled
      super
    end
    alias_method :merge_requests_ff_only_enabled?, :merge_requests_ff_only_enabled

    override :disabled_services
    def disabled_services
      strong_memoize(:disabled_services) do
        disabled_services = []

        unless feature_available?(:jenkins_integration)
          disabled_services.push('jenkins', 'jenkins_deprecated')
        end

        unless feature_available?(:github_project_service_integration)
          disabled_services.push('github')
        end

        disabled_services
      end
    end

    def pull_mirror_available?
      pull_mirror_available_overridden ||
        ::Gitlab::CurrentSettings.mirror_available
    end

    def external_authorization_classification_label
      return nil unless License.feature_available?(:external_authorization_service)

      super || ::Gitlab::CurrentSettings.current_application_settings
                 .external_authorization_service_default_label
    end

    override :licensed_features
    def licensed_features
      return super unless License.current

      License.current.features.select do |feature|
        License.global_feature?(feature) || licensed_feature_available?(feature)
      end
    end

    def any_path_locks?
      path_locks.any?
    end
    request_cache(:any_path_locks?) { self.id }

    def protected_environment_accessible_to?(environment_name, user)
      protected_environment = protected_environment_by_name(environment_name)

      !protected_environment || protected_environment.accessible_to?(user)
    end

    def protected_environment_by_name(environment_name)
      return nil unless protected_environments_feature_available?

      protected_environments.find_by(name: environment_name)
    end

    override :after_import
    def after_import
      super
      repository.log_geo_updated_event
      wiki.repository.log_geo_updated_event
    end

    override :import?
    def import?
      super || gitlab_custom_project_template_import?
    end

    def gitlab_custom_project_template_import?
      import_type == 'gitlab_custom_project_template' &&
        ::Gitlab::CurrentSettings.custom_project_templates_enabled?
    end

    def protected_environments_feature_available?
      Feature.enabled?('protected_environments') && feature_available?(:protected_environments)
    end

    # Because we use default_value_for we need to be sure
    # packages_enabled= method does exist even if we rollback migration.
    # Otherwise many tests from spec/migrations will fail.
    def packages_enabled=(value)
      if has_attribute?(:packages_enabled)
        write_attribute(:packages_enabled, value)
      end
    end

    private

    def set_override_pull_mirror_available
      self.pull_mirror_available_overridden = read_attribute(:mirror)
      true
    end

    def set_next_execution_timestamp_to_now
      import_state.set_next_execution_to_now
    end

    def licensed_feature_available?(feature)
      available_features = strong_memoize(:licensed_feature_available) do
        Hash.new do |h, feature|
          h[feature] = load_licensed_feature_available(feature)
        end
      end

      available_features[feature]
    end

    def load_licensed_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && namespace
        globally_available &&
          (public? && namespace.public? || namespace.feature_available_in_plan?(feature))
      else
        globally_available
      end
    end

    def validate_board_limit(board)
      # Board limits are disabled in EE, so this method is just a no-op.
    end

    override :after_rename_repository
    def after_rename_repository(full_path_before, path_before)
      super(full_path_before, path_before)

      ::Geo::RepositoryRenamedEventStore.new(
        self,
        old_path: path_before,
        old_path_with_namespace: full_path_before
      ).create
    end
  end
end
