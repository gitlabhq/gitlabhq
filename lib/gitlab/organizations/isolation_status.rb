# frozen_string_literal: true

module Gitlab
  module Organizations
    class IsolationStatus
      attr_reader :record, :changed_associations

      def initialize(record, changed_associations)
        @record = record
        @changed_associations = changed_associations
      end

      # rubocop:disable GitlabSecurity/PublicSend -- We need to dynamically check changed assocations
      def verify!
        my_organization = record.organization

        return unless my_organization && my_organization.isolated?

        changed_associations.each do |association|
          other = record.public_send(association)
          next if other.nil?

          other_organization = other.organization
          next if other_organization.nil?

          next unless my_organization != other_organization

          my_organization.mark_as_not_isolated!

          Gitlab::AppLogger.info(
            message: 'Isolation status set to false',
            organization_path: my_organization.path
          )
          break
        end
      end
      # rubocop:enable GitlabSecurity/PublicSend
    end
  end
end
