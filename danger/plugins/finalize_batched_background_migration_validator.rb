# frozen_string_literal: true

require_relative '../../tooling/danger/finalize_batched_background_migration_validator_helper'

module Danger
  class FinalizeBatchedBackgroundMigrationValidator < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::FinalizeBatchedBackgroundMigrationValidatorHelper
  end
end
