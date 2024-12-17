# frozen_string_literal: true

module Gitlab
  module ImportExport
    class AttributeCleaner
      ALLOWED_REFERENCES = [
        *Gitlab::ImportExport::Project::RelationFactory::PROJECT_REFERENCES,
        *Gitlab::ImportExport::Project::RelationFactory::USER_REFERENCES,
        'group_id',
        'commit_id',
        'discussion_id',
        'custom_attributes'
      ].freeze
      PROHIBITED_REFERENCES = Regexp.union(
        /\Acached_markdown_version\Z/,
        /_id\Z/,
        /_ids\Z/,
        /_html\Z/,
        /attributes/,
        /\Aremote_\w+_(url|urls|request_header)\Z/ # carrierwave automatically creates these attribute methods for uploads
      ).freeze

      ALLOWED_REFERENCES_PER_CLASS = {
        'Vulnerabilities::Scanner': ['external_id'],
        'Vulnerabilities::Identifier': ['external_id']
      }.freeze

      def self.clean(*args, **kwargs)
        new(*args, **kwargs).clean
      end

      def initialize(relation_hash:, relation_class:, excluded_keys: [])
        @relation_hash = relation_hash
        @relation_class = relation_class
        @excluded_keys = excluded_keys
      end

      def clean
        @relation_class.define_attribute_methods
        @relation_hash.reject do |key, _value|
          prohibited_key?(key) || !@relation_class.attribute_method?(key) || excluded_key?(key)
        end.except('id')
      end

      private

      def prohibited_key?(key)
        return false if ALLOWED_REFERENCES_PER_CLASS[@relation_class.name.to_sym]&.include?(key)

        key =~ PROHIBITED_REFERENCES && !permitted_key?(key)
      end

      def permitted_key?(key)
        ALLOWED_REFERENCES.include?(key)
      end

      def excluded_key?(key)
        return false if @excluded_keys.empty?

        @excluded_keys.include?(key)
      end
    end
  end
end
