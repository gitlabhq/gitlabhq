# frozen_string_literal: true

module Projects
  # Service class to detect target platforms of a project made for the Apple
  # Ecosystem.
  #
  # This service searches project.pbxproj and *.xcconfig files (contains build
  # settings) for the string "SDKROOT = <SDK_name>" where SDK_name can be
  # 'iphoneos', 'macosx', 'appletvos' or 'watchos'. Currently, the service is
  # intentionally limited (for performance reasons) to detect if a project
  # targets iOS.
  #
  # Ref: https://developer.apple.com/documentation/xcode/build-settings-reference/
  #
  # Example usage:
  # > AppleTargetPlatformDetectorService.new(a_project).execute
  # => []
  # > AppleTargetPlatformDetectorService.new(an_ios_project).execute
  # => [:ios]
  # > AppleTargetPlatformDetectorService.new(multiplatform_project).execute
  # => [:ios, :osx, :tvos, :watchos]
  class AppleTargetPlatformDetectorService < BaseService
    BUILD_CONFIG_FILENAMES = %w[project.pbxproj *.xcconfig].freeze

    # For the current iteration, we only want to detect when the project targets
    # iOS. In the future, we can use the same logic to detect projects that
    # target OSX, TvOS, and WatchOS platforms with SDK names 'macosx', 'appletvos',
    # and 'watchos', respectively.
    PLATFORM_SDK_NAMES = { ios: 'iphoneos' }.freeze

    def execute
      detect_platforms
    end

    private

    def file_finder
      @file_finder ||= ::Gitlab::FileFinder.new(project, project.default_branch)
    end

    def detect_platforms
      # Return array of SDK names for which "SDKROOT = <sdk_name>" setting
      # definition can be found in either project.pbxproj or *.xcconfig files.
      PLATFORM_SDK_NAMES.select do |_, sdk|
        config_files_containing_sdk_setting(sdk).present?
      end.keys
    end

    # Return array of project.pbxproj and/or *.xcconfig files
    # (Gitlab::Search::FoundBlob) that contain the setting definition string
    # "SDKROOT = <sdk_name>"
    def config_files_containing_sdk_setting(sdk)
      BUILD_CONFIG_FILENAMES.map do |filename|
        file_finder.find("SDKROOT = #{sdk} filename:#{filename}")
      end.flatten
    end
  end
end
