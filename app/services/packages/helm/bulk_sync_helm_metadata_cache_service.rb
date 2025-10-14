# frozen_string_literal: true

module Packages
  module Helm
    class BulkSyncHelmMetadataCacheService
      def initialize(user, package_files)
        @user = user
        @package_files = package_files
      end

      def execute
        metadata = ::Packages::Helm::FileMetadatum.for_package_files(package_files)
        .preload_projects
        .select_distinct_channel_and_project

        return ServiceResponse.success unless metadata.exists?

        ::Packages::Helm::CreateMetadataCacheWorker.bulk_perform_async_with_contexts(
          metadata,
          arguments_proc: ->(metadatum) { [metadatum.project_id, metadatum.channel] },
          context_proc: ->(metadatum) { { project: metadatum.project, user: user } }
        )

        ServiceResponse.success
      end

      private

      attr_reader :user, :package_files
    end
  end
end
