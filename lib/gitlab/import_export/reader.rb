module Gitlab
  module ImportExport
    class Reader
      attr_reader :tree

      def initialize(shared:)
        @shared = shared
        config_hash = YAML.load_file(Gitlab::ImportExport.config_file).deep_symbolize_keys
        @tree = config_hash[:project_tree]
        @attributes_finder = Gitlab::ImportExport::AttributesFinder.new(included_attributes: config_hash[:included_attributes],
                                                                        excluded_attributes: config_hash[:excluded_attributes],
                                                                        methods: config_hash[:methods])
      end

      # Outputs a hash in the format described here: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
      # for outputting a project in JSON format, including its relations and sub relations.
      def project_tree
        @attributes_finder.find_included(:project).merge(include: build_hash(@tree))
      rescue => e
        @shared.error(e)
        false
      end

      private

      # Builds a hash in the format described here: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
      #
      # +model_list+ - List of models as a relation tree to be included in the generated JSON, from the _import_export.yml_ file
      def build_hash(model_list)
        model_list.map do |model_objects|
          if model_objects.is_a?(Hash)
            build_json_config_hash(model_objects)
          else
            @attributes_finder.find(model_objects)
          end
        end
      end

      # Called when the model is actually a hash containing other relations (more models)
      # Returns the config in the right format for calling +to_json+
      # +model_object_hash+ - A model relationship such as:
      #   {:merge_requests=>[:merge_request_diff, :notes]}
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

      # If the model is a hash, process the sub_models, which could also be hashes
      # If there is a list, add to an existing array, otherwise use hash syntax
      # +current_key+ main model that will be a key in the hash
      # +model_object+ model or list of models to include in the hash
      def process_sub_model(current_key, model_object)
        sub_model_json = build_json_config_hash(model_object).dup
        @json_config_hash.slice!(current_key)

        if @json_config_hash[current_key] && @json_config_hash[current_key][:include]
          @json_config_hash[current_key][:include] << sub_model_json
        else
          @json_config_hash[current_key] = { include: sub_model_json }
        end
      end

      # Creates or adds to an existing hash an individual model or list
      # +current_key+ main model that will be a key in the hash
      # +model_object+ model or list of models to include in the hash
      def handle_model_object(current_key, model_object)
        if @json_config_hash[current_key]
          add_model_value(current_key, model_object)
        else
          create_model_value(current_key, model_object)
        end
      end

      # Constructs a new hash that will hold the configuration for that particular object
      # It may include exceptions or other attribute detail configuration, parsed by +@attributes_finder+
      # +current_key+ main model that will be a key in the hash
      # +value+ existing model to be included in the hash
      def create_model_value(current_key, value)
        parsed_hash = { include: value }

        @attributes_finder.parse(value) do |hash|
          parsed_hash = { include: hash_or_merge(value, hash) }
        end
        @json_config_hash[current_key] = parsed_hash
      end

      # Adds new model configuration to an existing hash with key +current_key+
      # It may include exceptions or other attribute detail configuration, parsed by +@attributes_finder+
      # +current_key+ main model that will be a key in the hash
      # +value+ existing model to be included in the hash
      def add_model_value(current_key, value)
        @attributes_finder.parse(value) { |hash| value = { value => hash } }
        old_values = @json_config_hash[current_key][:include]
        @json_config_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end

      # Construct a new hash or merge with an existing one a model configuration
      # This is to fulfil +to_json+ requirements.
      # +value+ existing model to be included in the hash
      # +hash+ hash containing configuration generated mainly from +@attributes_finder+
      def hash_or_merge(value, hash)
        value.is_a?(Hash) ? value.merge(hash) : { value => hash }
      end
    end
  end
end
