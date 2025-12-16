# frozen_string_literal: true

module Integrations
  module SlackWorkspace
    class ApiScope < ApplicationRecord
      self.table_name = 'slack_api_scopes'

      def self.find_or_initialize_by_names(names, organization_id:)
        found = where(name: names, organization_id: organization_id).to_a
        missing_names = names - found.pluck(:name)

        if missing_names.any?
          insert_all(missing_names.map { |name| { name: name, organization_id: organization_id } })
          missing = where(name: missing_names, organization_id: organization_id)
          found += missing
        end

        found
      end
    end
  end
end
