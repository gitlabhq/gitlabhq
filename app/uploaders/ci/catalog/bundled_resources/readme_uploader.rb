# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      class ReadmeUploader < GitlabUploader
        include ObjectStorage::Concern

        FILENAME = 'readme.json'

        storage_location :ci_catalog_bundles

        alias_method :upload, :model

        def store_dir
          ::Gitlab::Ci::Catalog::Bundle::ObjectKey.dir_for(model.bundled_resource, model.semver)
        end

        def filename
          FILENAME
        end
      end
    end
  end
end
