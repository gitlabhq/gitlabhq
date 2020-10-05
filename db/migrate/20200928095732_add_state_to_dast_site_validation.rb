# frozen_string_literal: true

class AddStateToDastSiteValidation < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20200928100408_add_text_limit_to_dast_site_validation_state.rb
  def change
    add_column :dast_site_validations, :state, :text, default: :pending, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
