# frozen_string_literal: true

class AddUserIdForeignKeyToMlExperiments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  NEW_FK_NAME = 'fk_ml_experiments_on_user_id'
  OLD_FK_NAME = 'fk_rails_1fbc5e001f'

  def up
    add_concurrent_foreign_key(:ml_experiments, :users, column: :user_id, on_delete: :nullify,
      name: NEW_FK_NAME, validate: true)

    with_lock_retries do
      remove_foreign_key_if_exists(:ml_experiments, name: OLD_FK_NAME)
    end
  end

  def down
    unless foreign_key_exists?(:ml_experiments, :users, name: OLD_FK_NAME)
      with_lock_retries do
        execute(<<~SQL.squish)
          ALTER TABLE ml_experiments ADD CONSTRAINT #{OLD_FK_NAME} FOREIGN KEY (user_id) REFERENCES users (id)
        SQL
      end
    end

    with_lock_retries do
      remove_foreign_key_if_exists(:ml_experiments, name: NEW_FK_NAME)
    end
  end
end
