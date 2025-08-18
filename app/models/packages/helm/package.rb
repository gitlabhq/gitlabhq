# frozen_string_literal: true

module Packages
  module Helm
    class Package < ::Packages::Package
      self.allow_legacy_sti_class = true

      validates :name, format: { with: Gitlab::Regex.helm_package_regex }
      validates :version, format: { with: Gitlab::Regex.helm_version_regex }

      def sync_helm_metadata_cache
        channel = package_files.first.helm_file_metadatum.channel
        ::Packages::Helm::CreateMetadataCacheWorker.perform_async(project_id, channel)
      end
    end
  end
end
