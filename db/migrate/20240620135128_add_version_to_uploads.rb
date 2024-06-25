# frozen_string_literal: true

class AddVersionToUploads < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :uploads, :version, :integer, null: false, default: 1
  end
end
