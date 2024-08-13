# frozen_string_literal: true

class AddSourceGroupIdToGroupCrmSettings < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :group_crm_settings, :source_group_id, :bigint
  end
end
