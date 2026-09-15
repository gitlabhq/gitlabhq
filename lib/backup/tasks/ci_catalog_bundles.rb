# frozen_string_literal: true

module Backup
  module Tasks
    class CiCatalogBundles < Task
      def self.id = 'ci_catalog_bundles'

      def human_name
        _('CI catalog bundles')
      end

      def destination_path
        'ci_catalog_bundles.tar.gz'
      end

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        Settings.ci_catalog_bundles.storage_path
      end
    end
  end
end
