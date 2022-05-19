# frozen_string_literal: true

class AddArkoseNamespaceToApplicationSettings < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  ARKOSE_LABS_DEFAULT_NAMESPACE = 'client'

  def up
    unless column_exists?(:application_settings, :arkose_labs_namespace)
      add_column :application_settings,
                 :arkose_labs_namespace,
                 :text,
                 default: ARKOSE_LABS_DEFAULT_NAMESPACE,
                 null: false
    end

    add_text_limit :application_settings, :arkose_labs_namespace, 255
  end

  def down
    remove_column :application_settings, :arkose_labs_namespace
  end
end
