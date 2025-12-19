# frozen_string_literal: true

module Integrations
  module SlackWorkspace
    class ApiScope < ApplicationRecord
      self.table_name = 'slack_api_scopes'

      def self.find_or_initialize_by_names(names, organization_id:)
        found = where(name: names, organization_id: organization_id).to_a
        missing_names = names - found.pluck(:name)

        if missing_names.any?
          upsert_all(missing_names.map { |name| { name: name, organization_id: organization_id } }, on_duplicate: :skip)
          missing = where(name: missing_names, organization_id: organization_id)
          found += missing
        end

        found
      end

      def self.find_or_initialize_by_names_and_organizations(names, organization_ids)
        organization_ids.index_with do |organization_id|
          find_or_initialize_by_names(names, organization_id: organization_id)
        end
      end
    end
  end
end
