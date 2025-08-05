# frozen_string_literal: true

module Packages
  module Helm
    class PackagesFinder
      include ::Packages::FinderHelper

      def initialize(project, channel, with_recent_limit: true)
        @project = project
        @channel = channel
        @with_recent_limit = with_recent_limit
      end

      def execute
        return ::Packages::Package.none if @channel.blank? || @project.blank?

        pkg_files = ::Packages::PackageFile.for_helm_with_channel(@project, @channel)

        # we use a subquery to get unique packages and at the same time
        # order + limit them.
        query = ::Packages::Package.id_in(pkg_files.select(:package_id))

        query = query.limit_recent(max_packages_count) if @with_recent_limit

        query
      end

      private

      def max_packages_count
        ::Gitlab::CurrentSettings.package_registry.fetch('helm_max_packages_count',
          ::ApplicationSetting::DEFAULT_HELM_MAX_PACKAGES_COUNT)
      end
    end
  end
end
