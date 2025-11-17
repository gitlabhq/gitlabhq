# frozen_string_literal: true

require_relative '../../tooling/danger/database_upgrade_ddl_lock'

module Danger
  class DatabaseUpgradeDdlLock < ::Danger::Plugin
    include Tooling::Danger::DatabaseUpgradeDdlLock
  end
end
