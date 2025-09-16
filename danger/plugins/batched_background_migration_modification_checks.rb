# frozen_string_literal: true

require_relative '../../tooling/danger/batched_background_migration_modification_checks_helper'

module Danger
  class BatchedBackgroundMigrationModificationChecks < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::BatchedBackgroundMigrationModificationChecksHelper
  end
end
