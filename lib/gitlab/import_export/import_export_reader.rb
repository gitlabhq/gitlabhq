module Gitlab
  module ImportExport
    class ImportExportReader

      def initialize(shared:)
        @shared = shared
        config_hash = YAML.load_file(Gitlab::ImportExport.config_file).deep_symbolize_keys
        @tree = config_hash[:project_tree]
        @attributes_finder = Gitlab::ImportExport::AttributesFinder.new(included_attributes: config_hash[:included_attributes],
                                                                        excluded_attributes: config_hash[:excluded_attributes],
                                                                        methods: config_hash[:methods])
      end

      def project_tree
        @attributes_finder.find_included(:project).merge(include: build_hash(@tree))
      rescue => e
        @shared.error(e.message)
        false
      end

      private

      def build_hash(model_list)
        model_list.map do |model_objects|
          if model_objects.is_a?(Hash)
            build_json_config_hash(model_objects)
          else
            @attributes_finder.find(model_objects)
          end
        end
      end

      def build_json_config_hash(model_object_hash)
        @json_config_hash = {}

        model_object_hash.values.flatten.each do |model_object|
          current_key = model_object_hash.keys.first

          @attributes_finder.parse(current_key) { |hash| @json_config_hash[current_key] ||= hash }

          handle_model_object(current_key, model_object)
          process_sub_model(current_key, model_object) if model_object.is_a?(Hash)
        end
        @json_config_hash
      end

      def process_sub_model(current_key, model_object)
        sub_model_json = build_json_config_hash(model_object).dup
        @json_config_hash.slice!(current_key)

        if @json_config_hash[current_key] && @json_config_hash[current_key][:include]
          @json_config_hash[current_key][:include] << sub_model_json
        else
          @json_config_hash[current_key] = { include: sub_model_json }
        end
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

        @attributes_finder.parse(value) do |hash|
          parsed_hash = { include: hash_or_merge(value, hash) }
        end
        @json_config_hash[current_key] = parsed_hash
      end

      def add_model_value(current_key, value)
        @attributes_finder.parse(value) { |hash| value = { value => hash } }
        old_values = @json_config_hash[current_key][:include]
        @json_config_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end

      def hash_or_merge(value, hash)
        value.is_a?(Hash) ? value.merge(hash) : { value => hash }
      end
    end
  end
end
