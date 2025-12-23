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
      self.class.sharding_keys.reduce(nil) do |found, (column, table)|
        next found unless ApplicationRecord.connection.data_source_exists?(table)

        record_id = attributes[column]
        next found unless record_id

        org = if table == 'organizations'
                ::Organizations::Organization.find_by(id: record_id)
              else
                ::Organizations::Organization.joins(table.to_sym).find_by(table => { id: record_id })
              end

        next found unless org

        next nil if found && found.id != org.id

        org
      end
    end
  end
end
