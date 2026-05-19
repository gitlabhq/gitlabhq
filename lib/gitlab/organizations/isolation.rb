# frozen_string_literal: true

module Gitlab
  module Organizations
    class Isolation
      # rubocop:disable Gitlab/AvoidCurrentOrganization -- We check if Current.organization is assigned so it is safe
      def self.enabled?
        return false unless Feature.enabled?(:data_isolation, Feature.current_request)
        return false unless ::Current.organization_assigned

        # Disable organization scoping because checking isolation state can raise a ThreadError
        return false unless Gitlab::Database::DataIsolation::ScopeHelper.without_data_isolation do
          ::Current.organization&.isolated?
        end

        true
      end
      # rubocop:enable Gitlab/AvoidCurrentOrganization
    end
  end
end
