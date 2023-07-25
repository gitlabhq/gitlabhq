# frozen_string_literal: true

require_relative '../../tooling/danger/bulk_database_actions'

module Danger
  class BulkDatabaseActions < ::Danger::Plugin
    include Tooling::Danger::BulkDatabaseActions
  end
end
