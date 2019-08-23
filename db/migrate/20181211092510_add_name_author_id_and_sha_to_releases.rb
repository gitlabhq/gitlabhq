# frozen_string_literal: true

class AddNameAuthorIdAndShaToReleases < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :releases, :author_id, :integer
    add_column :releases, :name, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :releases, :sha, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
