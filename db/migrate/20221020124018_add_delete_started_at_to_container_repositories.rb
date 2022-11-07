# frozen_string_literal: true

class AddDeleteStartedAtToContainerRepositories < Gitlab::Database::Migration[2.0]
  def change
    add_column :container_repositories,
               :delete_started_at,
               :datetime_with_timezone,
               null: true,
               default: nil
  end
end
