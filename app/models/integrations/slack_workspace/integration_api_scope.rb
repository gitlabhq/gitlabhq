# frozen_string_literal: true

module Integrations
  module SlackWorkspace
    class IntegrationApiScope < ApplicationRecord
      self.table_name = 'slack_integrations_scopes'

      belongs_to :slack_api_scope, class_name: 'Integrations::SlackWorkspace::ApiScope'
      belongs_to :slack_integration

      # Efficient scope propagation
      def self.update_scopes(integration_ids, scopes)
        return if integration_ids.empty?

        scope_ids = scopes.pluck(:id)

        attrs = scope_ids.flat_map do |scope_id|
          integration_ids.map { |si_id| { slack_integration_id: si_id, slack_api_scope_id: scope_id } }
        end

        # We don't know which ones to preserve - so just delete them all in a single query
        transaction do
          where(slack_integration_id: integration_ids).delete_all
          insert_all(attrs) unless attrs.empty?
        end
      end
    end
  end
end
