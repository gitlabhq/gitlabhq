# frozen_string_literal: true

class AddPreviousWeightToResourceWeightEvents < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def change
    add_column :resource_weight_events, :previous_weight, :integer
  end
end
