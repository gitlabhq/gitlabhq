module Gitlab
  module ImportExport
    class AttributeCleaner
      IGNORED_REFERENCES = Gitlab::ImportExport::RelationFactory::PROJECT_REFERENCES + Gitlab::ImportExport::RelationFactory::USER_REFERENCES

      def self.clean!(relation_hash:)
        relation_hash.select! do |key, _value|
          IGNORED_REFERENCES.include?(key) || !key.end_with?('_id')
        end
      end
    end
  end
end
