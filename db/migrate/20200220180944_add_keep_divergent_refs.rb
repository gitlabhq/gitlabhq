# frozen_string_literal: true

class AddKeepDivergentRefs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :remote_mirrors, :keep_divergent_refs, :boolean
  end
end
