# frozen_string_literal: true

class IncreaseDefaultDiffMaxPatchBytes < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default(:application_settings, :diff_max_patch_bytes, from: 102400, to: 204800)
  end
end
