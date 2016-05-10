module Gitlab
  module ImportExport
    class ImportExportReader

      def initialize(config: 'lib/gitlab/import_export/import_export.yml')
        config_hash = YAML.load_file(config).with_indifferent_access
        @tree = config_hash[:project_tree]
        @attributes_parser = Gitlab::ImportExport::AttributesFinder.new(included_attributes: config_hash[:included_attributes],
                                                                        excluded_attributes: config_hash[:excluded_attributes])
        @json_config_hash = {}
      end

      def project_tree
        @attributes_parser.find_included(:project).merge(include: build_hash(@tree))
      end

      private

      def build_hash(model_list)
        model_list.map do |model_objects|
          if model_objects.is_a?(Hash)
            build_json_config_hash(model_objects)
          else
            @attributes_parser.find(model_objects)
          end
        end
      end

      def build_json_config_hash(model_object_hash)
        model_object_hash.values.flatten.each do |model_object|
          current_key = model_object_hash.keys.first

          @attributes_parser.parse(current_key) { |hash| @json_config_hash[current_key] ||= hash }

          handle_model_object(current_key, model_object)
        end
        @json_config_hash
      end

      def handle_model_object(current_key, model_object)
        if @json_config_hash[current_key]
          add_model_value(current_key, model_object)
        else
          create_model_value(current_key, model_object)
        end
      end

      def create_model_value(current_key, value)
        parsed_hash = { include: value }

        @attributes_parser.parse(value) do |hash|
            parsed_hash = { include: hash_or_merge(value, hash) }
        end
        @json_config_hash[current_key] = parsed_hash
      end

      def add_model_value(current_key, value)
        @attributes_parser.parse(value) { |hash| value = { value => hash } }
        old_values = @json_config_hash[current_key][:include]
        @json_config_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end

      def hash_or_merge(value, hash)
        value.is_a?(Hash) ? value.merge(hash) : hash
      end
    end
  end
end
