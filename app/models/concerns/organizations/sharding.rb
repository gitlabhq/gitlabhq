# frozen_string_literal: true

module Organizations
  module Sharding
    extend ActiveSupport::Concern

    included do
      after_update_commit :check_organization_isolation_status
    end

    class << self
      # Skips scheduling CheckOrganizationIsolationStatusWorker for updates
      # committed inside the block. Only use on code paths where the check is
      # a known no-op: https://gitlab.com/gitlab-org/gitlab/-/issues/606395
      def skip_isolation_check
        previous = Thread.current[:organizations_skip_isolation_check]
        Thread.current[:organizations_skip_isolation_check] = true

        yield
      ensure
        Thread.current[:organizations_skip_isolation_check] = previous
      end

      def skip_isolation_check?
        !!Thread.current[:organizations_skip_isolation_check]
      end
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
      return if Sharding.skip_isolation_check?
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
