# frozen_string_literal: true

module Projects
  # Service class to detect if a project is made to run on the Android platform.
  #
  # This service searches for an AndroidManifest.xml file which all Android app
  # project must have. It returns the symbol :android if the given project is an
  # Android app project.
  #
  # Ref: https://developer.android.com/guide/topics/manifest/manifest-intro
  #
  # Example usage:
  # > AndroidTargetPlatformDetectorService.new(a_project).execute
  # => nil
  # > AndroidTargetPlatformDetectorService.new(an_android_project).execute
  # => :android
  class AndroidTargetPlatformDetectorService < BaseService
    # <manifest> element is required and must occur once inside AndroidManifest.xml
    MANIFEST_FILE_SEARCH_QUERY = '<manifest filename:AndroidManifest.xml'

    def execute
      detect
    end

    private

    def file_finder
      @file_finder ||= ::Gitlab::FileFinder.new(project, project.default_branch)
    end

    def detect
      return :android if file_finder.find(MANIFEST_FILE_SEARCH_QUERY).present?
    end
  end
end
