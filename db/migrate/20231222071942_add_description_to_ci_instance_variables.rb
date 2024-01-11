# frozen_string_literal: true

class AddDescriptionToCiInstanceVariables < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns -- text limit is added in 20231222072237_add_text_limit_to_ci_instance_variables_description.rb migration
  def change
    add_column(:ci_instance_variables, :description, :text)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
