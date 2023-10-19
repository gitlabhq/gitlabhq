# frozen_string_literal: true

module Projects
  class RecordTargetPlatformsWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 1.hour.to_i
    APPLE_PLATFORM_LANGUAGES = %w[swift objective-c].freeze

    feature_category :activation
    data_consistency :always
    deduplicate :until_executed
    urgency :low
    idempotent!

    def perform(project_id)
      @project = Project.find_by_id(project_id)

      return unless project
      return unless detector_service

      try_obtain_lease do
        @target_platforms = Projects::RecordTargetPlatformsService.new(project, detector_service).execute
        log_target_platforms_metadata
      end
    end

    private

    attr_reader :target_platforms, :project

    def detector_service
      return if target_languages.blank?

      AppleTargetPlatformDetectorService
    end

    def target_languages
      @target_languages ||= project.repository_languages.with_programming_language(*APPLE_PLATFORM_LANGUAGES)
    end

    def log_target_platforms_metadata
      return unless target_platforms.present?

      log_extra_metadata_on_done(:target_platforms, target_platforms)
    end

    def lease_key
      @lease_key ||= "#{self.class.name.underscore}:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def lease_release?
      false
    end
  end
end
