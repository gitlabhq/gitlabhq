# frozen_string_literal: true

class AddDomainToCluster < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :clusters, :domain, :string
  end
end
