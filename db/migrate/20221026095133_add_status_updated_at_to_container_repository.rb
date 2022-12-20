# frozen_string_literal: true

class AddStatusUpdatedAtToContainerRepository < Gitlab::Database::Migration[2.0]
  def change
    add_column :container_repositories, :status_updated_at, :datetime_with_timezone
  end
end
