# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class BaseConfig
      include Gitlab::Utils::StrongMemoize

      def initialize(portable)
        @portable = portable
      end

      def portable_tree
        attributes_finder.find_root(portable_class_sym)
      end

      def export_path
        strong_memoize(:export_path) do
          relative_path = File.join(base_export_path, SecureRandom.hex)

          ::Gitlab::ImportExport.export_path(relative_path: relative_path)
        end
      end

      def portable_relations
        import_export_config.dig(:tree, portable_class_sym).keys.map(&:to_s)
      end

      private

      attr_reader :portable

      def attributes_finder
        strong_memoize(:attributes_finder) do
          ::Gitlab::ImportExport::AttributesFinder.new(config: import_export_config)
        end
      end

      def import_export_config
        ::Gitlab::ImportExport::Config.new(config: import_export_yaml).to_h
      end

      def portable_class
        @portable_class ||= portable.class
      end

      def portable_class_sym
        @portable_class_sym ||= portable_class.to_s.demodulize.underscore.to_sym
      end

      def import_export_yaml
        raise NotImplementedError
      end

      def base_export_path
        raise NotImplementedError
      end
    end
  end
end
