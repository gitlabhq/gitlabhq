# frozen_string_literal: true

module Packages
  module Helm
    class PackagesFinder
      include ::Packages::FinderHelper

      MAX_PACKAGES_COUNT = 1000

      def initialize(project, channel)
        @project = project
        @channel = channel
      end

      def execute
        return ::Packages::Package.none if @channel.blank? || @project.blank?

        pkg_files = ::Packages::PackageFile.for_helm_with_channel(@project, @channel)

        # we use a subquery to get unique packages and at the same time
        # order + limit them.
        ::Packages::Package
          .limit_recent(MAX_PACKAGES_COUNT)
          .id_in(pkg_files.select(:package_id))
      end
    end
  end
end
