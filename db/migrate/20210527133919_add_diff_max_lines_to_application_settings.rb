# frozen_string_literal: true

class AddDiffMaxLinesToApplicationSettings < ActiveRecord::Migration[6.0]
  def change
    add_column(:application_settings,
               :diff_max_lines,
               :integer,
               default: 50000,
               null: false)
  end
end
