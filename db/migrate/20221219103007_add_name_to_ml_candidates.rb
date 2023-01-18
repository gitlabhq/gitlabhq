# frozen_string_literal: true
class AddNameToMlCandidates < Gitlab::Database::Migration[2.1]
  def change
    add_column :ml_candidates, :name, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
