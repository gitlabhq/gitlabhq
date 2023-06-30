# frozen_string_literal: true

class AddDescriptionToCiVariable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # text limit is added in a 20230621072848_add_text_limit_to_ci_variable_description.rb migration
  def change
    add_column(:ci_variables, :description, :text)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
