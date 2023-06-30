# frozen_string_literal: true

class AddDescriptionToCiGroupVariable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # text limit is added in a 20230621083052_add_text_limit_to_ci_group_variable_description.rb migration
  def change
    add_column(:ci_group_variables, :description, :text)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
