# frozen_string_literal: true

class AddUniqueConstraintForCustomEmailToServiceDeskSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'custom_email_unique_constraint'

  def up
    # Force custom_email to be unique instance-wide. This is neccessary because we will match
    # incoming service desk emails with a custom email by the custom_email field.
    # This also adds the corresponding index
    add_concurrent_index(:service_desk_settings, :custom_email, unique: true, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:service_desk_settings, INDEX_NAME)
  end
end
