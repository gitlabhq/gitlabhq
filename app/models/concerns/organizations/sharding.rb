# frozen_string_literal: true

module Organizations
  module Sharding
    extend ActiveSupport::Concern

    class_methods do
      def sharding_keys
        @sharding_keys ||= Gitlab::Database::Dictionary.entry(table_name)&.sharding_key || {}
      end
    end

    def sharding_organization
      self.class.sharding_keys.each do |column, table|
        parent_record_id = attributes[column]
        next unless parent_record_id

        case table
        when 'projects'
          return ::Organizations::Organization.joins(:projects).where(
            projects: { id: parent_record_id }
          ).first
        when 'namespaces'
          return ::Organizations::Organization.joins(:namespaces).where(
            namespaces: { id: parent_record_id }
          ).first
        when 'users'
          return ::Organizations::Organization.joins(
            'INNER JOIN users ON users.organization_id = organizations.id'
          ).where(users: { id: parent_record_id }).first
        when 'organizations'
          return ::Organizations::Organization.find_by_id(parent_record_id)
        end
      end

      nil
    end
  end
end
