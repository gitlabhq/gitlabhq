# frozen_string_literal: true

class AddPackageIdToMlCandidates < Gitlab::Database::Migration[2.1]
  def change
    add_column :ml_candidates, :package_id, :bigint, null: true
  end
end
