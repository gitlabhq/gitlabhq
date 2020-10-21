# frozen_string_literal: true

class AddTextLimitToRequirementsDescription < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :requirements, :description, 10_000
  end

  def down
    remove_text_limit :requirements, :description
  end
end
