module Gitlab
  module ImportExport
    class AttributeCleaner
      ALLOWED_REFERENCES = RelationFactory::PROJECT_REFERENCES + RelationFactory::USER_REFERENCES + ['group_id']

      def self.clean!(relation_hash:)
        relation_hash.reject! do |key, _value|
          key.end_with?('_id') && !ALLOWED_REFERENCES.include?(key)
        end
      end
    end
  end
end
