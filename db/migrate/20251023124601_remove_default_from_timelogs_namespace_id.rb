# frozen_string_literal: true

class RemoveDefaultFromTimelogsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    change_column_default :timelogs, :namespace_id, from: 0, to: nil
  end
end
