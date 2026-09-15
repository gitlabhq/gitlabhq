# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class CiCatalogBundles < Task
          def self.id = 'ci_catalog_bundles'

          def human_name = 'CI Catalog Bundles'

          def destination_path = 'ci_catalog_bundles.tar.gz'

          private

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path, excludes: ['tmp'])
          end

          def storage_path = context.ci_catalog_bundles_path
        end
      end
    end
  end
end
