# frozen_string_literal: true

class AddProjectIdToCiBuildNeeds < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :ci_build_needs, :project_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
end
