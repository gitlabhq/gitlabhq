# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      class ComponentUploader < GitlabUploader
        include ObjectStorage::Concern

        storage_location :ci_catalog_bundles

        alias_method :upload, :model

        def store_dir
          object_key.dir
        end

        def filename
          object_key.filename
        end

        private

        def object_key
          ::Gitlab::Ci::Catalog::Bundle::ObjectKey.new(model)
        end
      end
    end
  end
end
