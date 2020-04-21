# frozen_string_literal: true
class AddFilepathToReleaseLinks < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :release_links, :filepath, :string, limit: 128 # rubocop:disable Migration/PreventStrings
  end
end
