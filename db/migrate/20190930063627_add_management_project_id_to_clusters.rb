# frozen_string_literal: true

class AddManagementProjectIdToClusters < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :clusters, :management_project_id, :integer
  end
end
