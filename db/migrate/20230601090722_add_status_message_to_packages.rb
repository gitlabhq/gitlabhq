# frozen_string_literal: true

class AddStatusMessageToPackages < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230601153401_add_text_limit_to_packages_status_message
  def change
    add_column :packages_packages, :status_message, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
