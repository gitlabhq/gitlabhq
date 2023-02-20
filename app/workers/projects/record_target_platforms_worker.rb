# frozen_string_literal: true

module Projects
  class RecordTargetPlatformsWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 1.hour.to_i
    APPLE_PLATFORM_LANGUAGES = %w(swift objective-c).freeze
    ANDROID_PLATFORM_LANGUAGES = %w(java kotlin).freeze

    feature_category :projects
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
      if uses_apple_platform_languages?
        AppleTargetPlatformDetectorService
      elsif uses_android_platform_languages? && detect_android_projects_enabled?
        AndroidTargetPlatformDetectorService
      end
    end

    def detect_android_projects_enabled?
      Feature.enabled?(:detect_android_projects, project)
    end

    def uses_apple_platform_languages?
      target_languages.with_programming_language(*APPLE_PLATFORM_LANGUAGES).present?
    end

    def uses_android_platform_languages?
      target_languages.with_programming_language(*ANDROID_PLATFORM_LANGUAGES).present?
    end

    def target_languages
      languages = APPLE_PLATFORM_LANGUAGES + ANDROID_PLATFORM_LANGUAGES
      @target_languages ||= project.repository_languages.with_programming_language(*languages)
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
