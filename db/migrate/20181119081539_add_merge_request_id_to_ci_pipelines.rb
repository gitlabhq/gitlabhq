# frozen_string_literal: true

class AddMergeRequestIdToCiPipelines < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :ci_pipelines, :merge_request_id, :integer
  end

  def down
    remove_column :ci_pipelines, :merge_request_id, :integer
  end
end
