# frozen_string_literal: true

module ClickHouse
  module Models
    class AuditEvent < ClickHouse::Models::BaseModel
      def self.table_name
        'audit_events'
      end

      def by_entity_type(entity_type)
        where(entity_type: entity_type)
      end

      def by_entity_id(entity_id)
        where(entity_id: entity_id)
      end

      def by_author_id(author_id)
        where(author_id: author_id)
      end

      def by_entity_username(username)
        where(entity_id: self.class.find_user_id(username))
      end

      def by_author_username(username)
        where(author_id: self.class.find_user_id(username))
      end

      def self.by_entity_type(entity_type)
        new.by_entity_type(entity_type)
      end

      def self.by_entity_id(entity_id)
        new.by_entity_id(entity_id)
      end

      def self.by_author_id(author_id)
        new.by_author_id(author_id)
      end

      def self.by_entity_username(username)
        new.by_entity_username(username)
      end

      def self.by_author_username(username)
        new.by_author_username(username)
      end

      def self.find_user_id(username)
        ::User.find_by_username(username)&.id
      end
    end
  end
end
