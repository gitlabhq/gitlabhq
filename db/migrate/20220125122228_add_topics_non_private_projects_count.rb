# frozen_string_literal: true

class AddTopicsNonPrivateProjectsCount < Gitlab::Database::Migration[1.0]
  def up
    add_column :topics, :non_private_projects_count, :bigint, null: false, default: 0
  end

  def down
    remove_column :topics, :non_private_projects_count
  end
end
