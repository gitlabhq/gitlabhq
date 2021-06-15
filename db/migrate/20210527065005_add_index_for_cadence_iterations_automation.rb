# frozen_string_literal: true

class AddIndexForCadenceIterationsAutomation < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'cadence_create_iterations_automation'

  disable_ddl_transaction!

  def up
    # no-op
  end

  def down
    # no-op
  end
end
