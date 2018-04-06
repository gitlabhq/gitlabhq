module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Project` model
  module Project
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      include Elastic::ProjectsSearch
      prepend ImportStatusStateMachine
      include EE::DeploymentPlatform
      include EachBatch

      before_validation :mark_remote_mirrors_for_removal

      before_save :set_override_pull_mirror_available, unless: -> { ::Gitlab::CurrentSettings.mirror_available }
      after_save :create_mirror_data, if: ->(project) { project.mirror? && project.mirror_changed? }
      after_save :destroy_mirror_data, if: ->(project) { !project.mirror? && project.mirror_changed? }

      after_update :remove_mirror_repository_reference,
        if: ->(project) { project.mirror? && project.import_url_updated? }

      belongs_to :mirror_user, foreign_key: 'mirror_user_id', class_name: 'User'

      has_one :repository_state, class_name: 'ProjectRepositoryState', inverse_of: :project
      has_one :mirror_data, autosave: true, class_name: 'ProjectMirrorData'
      has_one :push_rule, ->(project) { project&.feature_available?(:push_rules) ? all : none }
      has_one :index_status
      has_one :jenkins_service
      has_one :jenkins_deprecated_service
      has_one :github_service

      has_many :approvers, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :audit_events, as: :entity
      has_many :remote_mirrors, inverse_of: :project
      has_many :path_locks

      has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_project_id

      has_many :source_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :project_id

      scope :with_shared_runners_limit_enabled, -> { with_shared_runners.non_public_only }

      scope :mirror, -> { where(mirror: true) }

      scope :mirrors_to_sync, ->(freeze_at) do
        mirror.joins(:mirror_data).without_import_status(:scheduled, :started)
          .where("next_execution_timestamp <= ?", freeze_at)
          .where("project_mirror_data.retry_count <= ?", ::Gitlab::Mirror::MAX_RETRY)
      end

      scope :with_remote_mirrors, -> { joins(:remote_mirrors).where(remote_mirrors: { enabled: true }).distinct }
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

      accepts_nested_attributes_for :remote_mirrors,
        allow_destroy: true,
        reject_if: ->(attrs) { attrs[:id].blank? && attrs[:url].blank? }

      with_options if: :mirror? do
        validates :import_url, presence: true
        validates :mirror_user, presence: true
      end
    end

    module ClassMethods
      def search_by_visibility(level)
        where(visibility_level: ::Gitlab::VisibilityLevel.string_options[level])
      end

      def with_slack_application_disabled
        joins('LEFT JOIN services ON services.project_id = projects.id AND services.type = \'GitlabSlackApplicationService\' AND services.active IS true')
          .where('services.id IS NULL')
      end
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

      (mirror_data.last_update_started_at.to_i -
        mirror_data.last_update_scheduled_at.to_i).seconds
    end

    def mirror_update_duration
      return unless mirror?

      (mirror_last_update_at.to_i -
        mirror_data.last_update_started_at.to_i).seconds
    end

    def mirror_with_content?
      mirror? && !empty_repo?
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

      self.mirror_data.next_execution_timestamp <= Time.now
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
      self.mirror_data.retry_limit_exceeded?
    end

    def has_remote_mirror?
      feature_available?(:repository_mirrors) &&
        remote_mirror_available? &&
        remote_mirrors.enabled.exists?
    end

    def updating_remote_mirror?
      remote_mirrors.enabled.started.exists?
    end

    def update_remote_mirrors
      return unless feature_available?(:repository_mirrors) && remote_mirror_available?

      remote_mirrors.enabled.each(&:sync)
    end

    def mark_stuck_remote_mirrors_as_failed!
      remote_mirrors.stuck.update_all(
        update_status: :failed,
        last_error: 'The remote mirror took to long to complete.',
        last_update_at: Time.now
      )
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

      mirror_data = self.mirror_data

      mirror_data.set_next_execution_to_now
      mirror_data.reset_retry_count if mirror_data.retry_limit_exceeded?

      mirror_data.save!

      UpdateAllMirrorsWorker.perform_async
    end

    def add_import_job
      if import? && !repository_exists?
        super
      elsif mirror?
        ::Gitlab::Metrics.add_event(:mirrors_scheduled, path: full_path)
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

    def mark_remote_mirrors_for_removal
      remote_mirrors.each(&:mark_for_delete_if_blank_url)
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

    override :rename_repo
    def rename_repo
      super

      path_was = previous_changes['path'].first
      old_path_with_namespace = File.join(namespace.full_path, path_was)

      ::Geo::RepositoryRenamedEventStore.new(
        self,
        old_path: path_was,
        old_path_with_namespace: old_path_with_namespace
      ).create
    end

    # Override to reject disabled services
    def find_or_initialize_services(exceptions: [])
      available_services = super

      available_services.reject do |service|
        disabled_services.include?(service.to_param)
      end
    end

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

    def remote_mirror_available?
      remote_mirror_available_overridden ||
        ::Gitlab::CurrentSettings.mirror_available
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

    private

    def set_override_pull_mirror_available
      self.pull_mirror_available_overridden = read_attribute(:mirror)
      true
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

    def destroy_mirror_data
      mirror_data.destroy
    end

    def validate_board_limit(board)
      # Board limits are disabled in EE, so this method is just a no-op.
    end
  end
end
