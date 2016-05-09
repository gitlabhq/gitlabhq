module Gitlab
  module ImportExport
    class AttributesFinder
      def initialize(included_attributes:, excluded_attributes:)
        @included_attributes = included_attributes || {}
        @excluded_attributes = excluded_attributes || {}
      end

      def find(model_object)
        parsed_hash = find_attributes_only(model_object)
        parsed_hash.empty? ? model_object : { model_object => parsed_hash }
      end

      def parse(model_object)
        parsed_hash = find_attributes_only(model_object)
        yield parsed_hash unless parsed_hash.empty?
      end

      def find_included(value)
        key = key_from_hash(value)
        @included_attributes[key].nil? ? {} : { only: @included_attributes[key] }
      end

      def find_excluded(value)
        key = key_from_hash(value)
        @excluded_attributes[key].nil? ? {} : { except: @excluded_attributes[key] }
      end

      private

      def find_attributes_only(value)
        find_included(value).merge(find_excluded(value))
      end

      def key_from_hash(value)
        value.is_a?(Hash) ? value.keys.first : value
      end
    end
  end
end
