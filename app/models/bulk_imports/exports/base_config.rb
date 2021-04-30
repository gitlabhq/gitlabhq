# frozen_string_literal: true

module BulkImports
  module Exports
    class BaseConfig
      include Gitlab::Utils::StrongMemoize

      def initialize(exportable)
        @exportable = exportable
      end

      def exportable_tree
        attributes_finder.find_root(exportable_class_sym)
      end

      def validate_user_permissions!(user)
        user.can?(ability, exportable) ||
          raise(::Gitlab::ImportExport::Error.permission_error(user, exportable))
      end

      def export_path
        strong_memoize(:export_path) do
          relative_path = File.join(base_export_path, SecureRandom.hex)

          ::Gitlab::ImportExport.export_path(relative_path: relative_path)
        end
      end

      def exportable_relations
        import_export_config.dig(:tree, exportable_class_sym).keys.map(&:to_s)
      end

      private

      attr_reader :exportable

      def attributes_finder
        strong_memoize(:attributes_finder) do
          ::Gitlab::ImportExport::AttributesFinder.new(config: import_export_config)
        end
      end

      def import_export_config
        ::Gitlab::ImportExport::Config.new(config: import_export_yaml).to_h
      end

      def exportable_class
        @exportable_class ||= exportable.class
      end

      def exportable_class_sym
        @exportable_class_sym ||= exportable_class.to_s.downcase.to_sym
      end

      def import_export_yaml
        raise NotImplementedError
      end

      def ability
        raise NotImplementedError
      end

      def base_export_path
        raise NotImplementedError
      end
    end
  end
end
