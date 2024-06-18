# frozen_string_literal: true

class AddProjectIdToReleaseLinks < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :release_links, :project_id, :bigint
  end
end
