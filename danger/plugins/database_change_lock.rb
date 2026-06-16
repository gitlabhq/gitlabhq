# frozen_string_literal: true

require_relative '../../tooling/danger/database_change_lock'

module Danger
  class DatabaseChangeLock < ::Danger::Plugin
    include Tooling::Danger::DatabaseChangeLock
  end
end
