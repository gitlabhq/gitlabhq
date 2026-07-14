# frozen_string_literal: true

class AddUpdatedAtToPagesDomains < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_timestamps_with_timezone :pages_domains, columns: %i[updated_at], null: true
  end
end
