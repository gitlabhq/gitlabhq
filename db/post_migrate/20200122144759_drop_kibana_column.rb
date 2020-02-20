# frozen_string_literal: true

class DropKibanaColumn < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    remove_column :clusters_applications_elastic_stacks, :kibana_hostname, :string, limit: 255
  end
end
