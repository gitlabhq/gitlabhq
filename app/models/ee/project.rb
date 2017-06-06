module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Project` model
  module Project
    extend ActiveSupport::Concern

    prepended do
      include IgnorableColumn

      ignore_column :sync_time

      after_save :create_mirror_data, if: ->(project) { project.mirror? && project.mirror_changed? }
      after_save :destroy_mirror_data, if: ->(project) { !project.mirror? && project.mirror_changed? }

      has_one :mirror_data, dependent: :delete, autosave: true, class_name: 'ProjectMirrorData'

      scope :with_shared_runners_limit_enabled, -> { with_shared_runners.non_public_only }

      scope :mirrors_to_sync, -> do
        mirror.joins(:mirror_data).where("next_execution_timestamp <= ? AND import_status NOT IN ('scheduled', 'started')", Time.now).
          order_by(:next_execution_timestamp).limit(::Gitlab::Mirror.available_capacity)
      end

      scope :stuck_mirrors, -> do
        mirror.joins(:mirror_data).
          where("(import_status = 'started' AND project_mirror_data.last_update_started_at < :limit) OR (import_status = 'scheduled' AND project_mirror_data.last_update_scheduled_at < :limit)",
                { limit: 20.minutes.ago })
      end

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :statistics, allow_nil: true

      delegate :actual_shared_runners_minutes_limit,
        :shared_runners_minutes_used?, to: :namespace
    end

    def shared_runners_available?
      super && !namespace.shared_runners_minutes_used?
    end

    def shared_runners_minutes_limit_enabled?
      !public? && shared_runners_enabled? && namespace.shared_runners_minutes_limit_enabled?
    end

    # Checks licensed feature availability if `feature` matches any
    # key on License::FEATURE_CODES. Otherwise, check feature availability
    # through ProjectFeature.
    def feature_available?(feature, user = nil)
      if License::FEATURE_CODES.key?(feature)
        licensed_feature_available?(feature)
      else
        super
      end
    end

    def service_desk_address
      return nil unless service_desk_available?

      config = ::Gitlab.config.incoming_email
      wildcard = ::Gitlab::IncomingEmail::WILDCARD_PLACEHOLDER

      config.address&.gsub(wildcard, full_path)
    end

    def force_import_job!
      self.mirror_data.set_next_execution_to_now!
      UpdateAllMirrorsWorker.perform_async
    end

    def add_import_job
      if import? && !repository_exists?
        super
      elsif mirror?
        RepositoryUpdateMirrorWorker.perform_async(self.id)
      end
    end

    private

    def licensed_feature_available?(feature)
      globally_available = License.current&.feature_available?(feature)

      if current_application_settings.should_check_namespace_plan?
        globally_available &&
          (public? && namespace.public? || namespace.feature_available?(feature))
      else
        globally_available
      end
    end

    def destroy_mirror_data
      mirror_data.destroy
    end

    def service_desk_available?
      return @service_desk_available if defined?(@service_desk_available)

      @service_desk_available = EE::Gitlab::ServiceDesk.enabled? && service_desk_enabled?
    end
  end
end
