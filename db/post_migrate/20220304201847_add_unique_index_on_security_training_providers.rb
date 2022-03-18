# frozen_string_literal: true

class AddUniqueIndexOnSecurityTrainingProviders < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_security_training_providers_on_unique_name'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_training_providers, :name, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_training_providers, INDEX_NAME
  end
end
