# frozen_string_literal: true

class DropStageColumnFromCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    remove_column :p_ci_builds, :stage
  end

  def down
    add_column :p_ci_builds, :stage, :string
  end
end
