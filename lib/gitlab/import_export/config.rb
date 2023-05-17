# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Config
      def initialize(config: Gitlab::ImportExport.config_file)
        @config = config
        @hash = parse_yaml
        @hash.deep_symbolize_keys!
        @ee_hash = @hash.delete(:ee) || {}

        @hash[:tree] = normalize_tree(@hash[:tree])
        @hash[:import_only_tree] = normalize_tree(@hash[:import_only_tree] || {})
        @ee_hash[:tree] = normalize_tree(@ee_hash[:tree] || {})
      end

      # Returns a Hash of the YAML file, including EE specific data if EE is
      # used.
      def to_h
        if merge_ee?
          deep_merge(@hash, @ee_hash)
        else
          @hash
        end
      end

      private

      def deep_merge(hash_a, hash_b)
        hash_a.deep_merge(hash_b) do |_, this_val, other_val|
          this_val.to_a + other_val.to_a
        end
      end

      def normalize_tree(item)
        case item
        when Array
          item.reduce({}) do |hash, subitem|
            hash.merge!(normalize_tree(subitem))
          end
        when Hash
          item.transform_values(&method(:normalize_tree))
        when Symbol
          { item => {} }
        else
          raise ArgumentError, "#{item} needs to be Array, Hash, Symbol or NilClass"
        end
      end

      def merge_ee?
        Gitlab.ee?
      end

      def parse_yaml
        YAML.safe_load_file(@config, aliases: true, permitted_classes: [Symbol])
      end
    end
  end
end
