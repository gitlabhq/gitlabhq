module Gitlab
  module ImportExport
    class ImportExportReader
      #FIXME

      def initialize(config: 'lib/gitlab/import_export/import_export.yml')
        config_hash = YAML.load_file(config).with_indifferent_access
        @tree = config_hash[:project_tree]
        @attributes_parser = Gitlab::ImportExport::AttributesFinder.new(included_attributes: config_hash[:included_attributes],
                                                                        excluded_attributes: config_hash[:excluded_attributes])
      end

      def project_tree
        @attributes_parser.find_included(:project).merge(include: build_hash(@tree))
      end

      private

      def build_hash(model_list)
        model_list.map do |model_object_hash|
          if model_object_hash.is_a?(Hash)
            process_model_object(model_object_hash)
          else
            @attributes_parser.find(model_object_hash)
          end
        end
      end

      def process_model_object(model_object_hash, included_classes_hash = {})
        model_object_hash.values.flatten.each do |model_object|
          current_key = model_object_hash.keys.first
          model_object = process_current_class(model_object_hash, included_classes_hash, model_object)
          if included_classes_hash[current_key]
            add_to_class(current_key, included_classes_hash, model_object)
          else
            add_new_class(current_key, included_classes_hash, model_object)
          end
        end
        included_classes_hash
      end

      def process_current_class(hash, included_classes_hash, value)
        value = value.is_a?(Hash) ? process_model_object(hash, included_classes_hash) : value
        attributes_hash = @attributes_parser.find_attributes_only(hash.keys.first)
        included_classes_hash[hash.keys.first] ||= attributes_hash unless attributes_hash.empty?
        value
      end

      def add_new_class(current_key, included_classes_hash, value)
        attributes_hash = @attributes_parser.find_attributes_only(value)
        parsed_hash = { include: value }
        unless attributes_hash.empty?
          if value.is_a?(Hash)
            parsed_hash = { include: value.merge(attributes_hash) }
          else
            parsed_hash = { include: { value => attributes_hash } }
          end
        end
        included_classes_hash[current_key] = parsed_hash
      end

      def add_to_class(current_key, included_classes_hash, value)
        attributes_hash = @attributes_parser.find_attributes_only(value)
        value = { value => attributes_hash } unless attributes_hash.empty?
        old_values = included_classes_hash[current_key][:include]
        included_classes_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end
    end
  end
end
