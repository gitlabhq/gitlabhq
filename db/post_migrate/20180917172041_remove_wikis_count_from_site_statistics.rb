# frozen_string_literal: true
class RemoveWikisCountFromSiteStatistics < ActiveRecord::Migration[4.2]
  def change
    remove_column :site_statistics, :wikis_count, :integer
  end
end
