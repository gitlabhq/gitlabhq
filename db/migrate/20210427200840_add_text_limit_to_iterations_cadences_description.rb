# frozen_string_literal: true

class AddTextLimitToIterationsCadencesDescription < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :iterations_cadences, :description, 5000
  end

  def down
    remove_text_limit :iterations_cadences, :description
  end
end
