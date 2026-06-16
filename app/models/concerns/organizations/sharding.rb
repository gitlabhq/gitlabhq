# frozen_string_literal: true

module Organizations
  module Sharding
    extend ActiveSupport::Concern

    included do
      after_update_commit :check_organization_isolation_status
    end

    class_methods do
      def sharding_keys
        @sharding_keys ||= Gitlab::Database::Dictionary.entry(table_name)&.sharding_key || {}
      end
    end

    def organization
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

    def check_organization_isolation_status
      return unless Feature.enabled?(:isolation_status_check, Feature.current_request)
      return if self.class.sharding_keys.empty?

      changed_associations = self.class
        .reflect_on_all_associations(:belongs_to)
        .filter_map { |belongs_to| belongs_to.foreign_key if belongs_to.foreign_key.in?(saved_changes.keys) }

      return if changed_associations.empty?

      changes = saved_changes.slice(*changed_associations.map(&:to_s)).to_hash

      ::Organizations::CheckOrganizationIsolationStatusWorker.perform_async(self.class.name, id, changes)
    end
  end
end
