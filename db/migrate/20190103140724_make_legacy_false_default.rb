# frozen_string_literal: true

class MakeLegacyFalseDefault < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    change_column_default :cluster_providers_gcp, :legacy_abac, from: true, to: false
  end
end
