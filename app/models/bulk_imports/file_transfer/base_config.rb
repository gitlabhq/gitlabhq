# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class BaseConfig
      include Gitlab::Utils::StrongMemoize

      UPLOADS_RELATION = 'uploads'
      SELF_RELATION = 'self'
      USER_CONTRIBUTIONS_RELATION = 'user_contributions'

      def initialize(portable)
        @portable = portable
      end

      def portable_tree
        attributes_finder.find_root(portable_class_sym)
      end

      def top_relation_tree(relation)
        portable_relations_tree[relation.to_s]
      end

      def relation_excluded_keys(relation)
        attributes_finder.find_excluded_keys(relation)
      end

      def relation_included_keys(relation)
        attributes_finder.find_included_keys(relation)
      end

      def export_path
        @export_path ||= Dir.mktmpdir('bulk_imports')
      end

      def portable_relations
        tree_relations + file_relations + self_relation - skipped_relations
      end

      def batchable_relations
        portable_relations.select { |relation| portable_class.reflect_on_association(relation)&.collection? }
      end
      strong_memoize_attr :batchable_relations

      def batchable_relation?(relation)
        batchable_relations.include?(relation)
      end

      def self_relation?(relation)
        relation == SELF_RELATION
      end

      def tree_relation?(relation)
        tree_relations.include?(relation)
      end

      def file_relation?(relation)
        file_relations.include?(relation)
      end

      def relation_has_user_contributions?(relation)
        (relation_included_keys(relation) & ::Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES).any?
      end

      def user_contributions_relation?(relation)
        relation == USER_CONTRIBUTIONS_RELATION
      end

      def tree_relation_definition_for(relation)
        return unless tree_relation?(relation)

        portable_tree[:include].find { |include| include[relation.to_sym] }
      end

      def portable_relations_tree
        @portable_relations_tree ||= attributes_finder
          .find_relations_tree(portable_class_sym, include_import_only_tree: true).deep_stringify_keys
      end

      # Returns an export service class for the given relation.
      # @return TreeExportService if a relation is serializable and is listed in import_export.yml
      # @return FileExportService if a relation is a file (uploads, lfs objects, git repository, etc.)
      def export_service_for(relation)
        if tree_relation?(relation)
          ::BulkImports::TreeExportService
        elsif file_relation?(relation)
          ::BulkImports::FileExportService
        else
          raise ::BulkImports::Error, 'Unsupported export relation'
        end
      end

      private

      attr_reader :portable

      def attributes_finder
        strong_memoize(:attributes_finder) do
          ::Gitlab::ImportExport::AttributesFinder.new(config: import_export_config)
        end
      end

      def import_export_config
        @config ||= ::Gitlab::ImportExport::Config.new(config: import_export_yaml).to_h
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

      def tree_relations
        import_export_config.dig(:tree, portable_class_sym).keys.map(&:to_s)
      end

      def file_relations
        [UPLOADS_RELATION]
      end

      def skipped_relations
        []
      end

      def self_relation
        [SELF_RELATION]
      end
    end
  end
end
