# frozen_string_literal: true

require_relative '../../tooling/danger/bulk_database_actions'

module Danger
  class BulkDatabaseActions < ::Danger::Plugin
    def add_suggestions_for(filename)
      Tooling::Danger::BulkDatabaseActions.new(filename, context: self).suggest
    end
  end
end
