# frozen_string_literal: true

class AddNumberOfReplicasToZoektEnabledNamespaces < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    add_column :zoekt_enabled_namespaces, :number_of_replicas_override, :integer, null: true
  end

  def down
    remove_column :zoekt_enabled_namespaces, :number_of_replicas_override
  end
end
