# frozen_string_literal: true

class CreateUserFollowUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        CREATE TABLE user_follow_users (
          follower_id integer not null references users (id) on delete cascade,
          followee_id integer not null references users (id) on delete cascade,
          PRIMARY KEY (follower_id, followee_id)
        );
        CREATE INDEX ON user_follow_users (followee_id);
      SQL
    end
  end

  def down
    drop_table :user_follow_users
  end
end
