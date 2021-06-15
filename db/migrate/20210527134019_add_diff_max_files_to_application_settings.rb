# frozen_string_literal: true

class AddDiffMaxFilesToApplicationSettings < ActiveRecord::Migration[6.0]
  def change
    add_column(:application_settings,
               :diff_max_files,
               :integer,
               default: 1000,
               null: false)
  end
end
