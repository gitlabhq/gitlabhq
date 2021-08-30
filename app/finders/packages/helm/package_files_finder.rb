# frozen_string_literal: true

module Packages
  module Helm
    class PackageFilesFinder
      DEFAULT_PACKAGE_FILES_COUNT = 20
      MAX_PACKAGE_FILES_COUNT = 1000

      delegate :most_recent!, to: :execute

      def initialize(project, channel, params = {})
        @project = project
        @channel = channel
        @params = params
      end

      def execute
        package_files = Packages::PackageFile.for_helm_with_channel(@project, @channel)
                                             .limit_recent(limit)
        by_file_name(package_files)
      end

      private

      def limit
        limit_param = @params[:limit] || DEFAULT_PACKAGE_FILES_COUNT
        [limit_param, MAX_PACKAGE_FILES_COUNT].min
      end

      def by_file_name(files)
        return files unless @params[:file_name]

        files.with_file_name(@params[:file_name])
      end
    end
  end
end
