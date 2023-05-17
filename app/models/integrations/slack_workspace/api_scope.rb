# frozen_string_literal: true

module Integrations
  module SlackWorkspace
    class ApiScope < ApplicationRecord
      self.table_name = 'slack_api_scopes'

      def self.find_or_initialize_by_names(names)
        found = where(name: names).to_a
        missing_names = names - found.pluck(:name)

        if missing_names.any?
          insert_all(missing_names.map { |name| { name: name } })
          missing = where(name: missing_names)
          found += missing
        end

        found
      end
    end
  end
end
