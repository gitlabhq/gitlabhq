# frozen_string_literal: true

class ChangeClustersHelmMajorVersionDefaultTo3 < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default(:clusters, :helm_major_version, from: 2, to: 3)
  end
end
