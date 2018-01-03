# rubocop:disable Migration/Datetime
class AddLastUsedAtToKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :keys, :last_used_at, :datetime
  end
end
