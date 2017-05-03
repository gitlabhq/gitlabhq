module Gitlab
  module ImportExport
    class AttributeCleaner
      ALLOWED_REFERENCES = RelationFactory::PROJECT_REFERENCES + RelationFactory::USER_REFERENCES + ['group_id']

      def self.clean(*args)
        new(*args).clean
      end

      def initialize(relation_hash:, relation_class:)
        @relation_hash = relation_hash
        @relation_class = relation_class
      end

      def clean
        @relation_hash.reject do |key, _value|
          prohibited_key?(key) || !@relation_class.attribute_method?(key)
        end.except('id')
      end

      private

      def prohibited_key?(key)
        key.end_with?('_id') && !ALLOWED_REFERENCES.include?(key)
      end
    end
  end
end
