module Gitlab
  module ImportExport
    # Generates a hash that conforms with http://apidock.com/rails/Hash/to_json
    # and its peculiar options.
    class JsonHashBuilder
      def self.build(model_objects, attributes_finder)
        new(model_objects, attributes_finder).build
      end

      def initialize(model_objects, attributes_finder)
        @model_objects = model_objects
        @attributes_finder = attributes_finder
      end

      def build
        process_model_objects(@model_objects)
      end

      private

      # Called when the model is actually a hash containing other relations (more models)
      # Returns the config in the right format for calling +to_json+
      #
      # +model_object_hash+ - A model relationship such as:
      #   {:merge_requests=>[:merge_request_diff, :notes]}
      def process_model_objects(model_object_hash)
        json_config_hash = {}
        current_key = model_object_hash.keys.first

        model_object_hash.values.flatten.each do |model_object|
          @attributes_finder.parse(current_key) { |hash| json_config_hash[current_key] ||= hash }
          handle_model_object(current_key, model_object, json_config_hash)
        end

        json_config_hash
      end

      # Creates or adds to an existing hash an individual model or list
      #
      # +current_key+ main model that will be a key in the hash
      # +model_object+ model or list of models to include in the hash
      # +json_config_hash+ the original hash containing the root model
      def handle_model_object(current_key, model_object, json_config_hash)
        model_or_sub_model = model_object.is_a?(Hash) ? process_model_objects(model_object) : model_object

        if json_config_hash[current_key]
          add_model_value(current_key, model_or_sub_model, json_config_hash)
        else
          create_model_value(current_key, model_or_sub_model, json_config_hash)
        end
      end

      # Constructs a new hash that will hold the configuration for that particular object
      # It may include exceptions or other attribute detail configuration, parsed by +@attributes_finder+
      #
      # +current_key+ main model that will be a key in the hash
      # +value+ existing model to be included in the hash
      # +json_config_hash+ the original hash containing the root model
      def create_model_value(current_key, value, json_config_hash)
        json_config_hash[current_key] = parse_hash(value) || { include: value }
      end

      # Calls attributes finder to parse the hash and add any attributes to it
      #
      # +value+ existing model to be included in the hash
      # +parsed_hash+ the original hash
      def parse_hash(value)
        @attributes_finder.parse(value) do |hash|
          { include: hash_or_merge(value, hash) }
        end
      end

      # Adds new model configuration to an existing hash with key +current_key+
      # It may include exceptions or other attribute detail configuration, parsed by +@attributes_finder+
      #
      # +current_key+ main model that will be a key in the hash
      # +value+ existing model to be included in the hash
      # +json_config_hash+ the original hash containing the root model
      def add_model_value(current_key, value, json_config_hash)
        @attributes_finder.parse(value) { |hash| value = { value => hash } }

        add_to_array(current_key, json_config_hash, value)
      end

      # Adds new model configuration to an existing hash with key +current_key+
      # it creates a new array if it was previously a single value
      #
      # +current_key+ main model that will be a key in the hash
      # +value+ existing model to be included in the hash
      # +json_config_hash+ the original hash containing the root model
      def add_to_array(current_key, json_config_hash, value)
        old_values = json_config_hash[current_key][:include]

        json_config_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end

      # Construct a new hash or merge with an existing one a model configuration
      # This is to fulfil +to_json+ requirements.
      #
      # +hash+ hash containing configuration generated mainly from +@attributes_finder+
      # +value+ existing model to be included in the hash
      def hash_or_merge(value, hash)
        value.is_a?(Hash) ? value.merge(hash) : { value => hash }
      end
    end
  end
end
