# frozen_string_literal: true

class AddStartAndEndTimesToTargetedMessages < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  CONSTRAINT_NAME = 'check_targeted_messages_starts_at_before_ends_at'

  def up
    # rubocop:disable Rails/NotNullColumn -- No default value needed as there is no existing data
    add_column :targeted_messages, :starts_at, :datetime_with_timezone, null: false, if_not_exists: true
    add_column :targeted_messages, :ends_at, :datetime_with_timezone, null: false, if_not_exists: true
    # rubocop:enable Rails/NotNullColumn

    add_check_constraint :targeted_messages,
      'starts_at < ends_at',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :targeted_messages, CONSTRAINT_NAME

    remove_column :targeted_messages, :starts_at, if_exists: true
    remove_column :targeted_messages, :ends_at, if_exists: true
  end
end
