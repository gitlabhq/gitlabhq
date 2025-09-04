# frozen_string_literal: true

module Packages
  module Helm
    class Package < ::Packages::Package
      self.allow_legacy_sti_class = true

      validates :name, format: { with: Gitlab::Regex.helm_package_regex }
      validates :version, format: { with: Gitlab::Regex.helm_version_regex }

      def sync_helm_metadata_caches(user)
        metadata = ::Packages::Helm::FileMetadatum.for_package_files(package_files)
        .select_distinct_channel

        return if metadata.blank?

        ::Packages::Helm::CreateMetadataCacheWorker.bulk_perform_async_with_contexts(
          metadata,
          arguments_proc: ->(metadatum) { [project_id, metadatum.channel] },
          context_proc: ->(_) { { project: project, user: user } }
        )
      end
    end
  end
end
