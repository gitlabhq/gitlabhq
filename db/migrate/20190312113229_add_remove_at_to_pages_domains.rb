# frozen_string_literal: true

class AddRemoveAtToPagesDomains < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  def change
    add_column :pages_domains, :remove_at, :datetime_with_timezone
  end
end
