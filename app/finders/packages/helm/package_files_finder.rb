# frozen_string_literal: true

module Packages
  module Helm
    class PackageFilesFinder
      def initialize(project, channel, params = {})
        @project = project
        @channel = channel
        @params = params
      end

      def execute
        package_files = Packages::PackageFile.for_helm_with_channel(@project, @channel).preload_helm_file_metadata
        by_file_name(package_files)
      end

      private

      def by_file_name(files)
        return files unless @params[:file_name]

        files.with_file_name(@params[:file_name])
      end
    end
  end
end
