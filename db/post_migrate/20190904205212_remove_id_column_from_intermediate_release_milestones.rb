# frozen_string_literal: true

class RemoveIdColumnFromIntermediateReleaseMilestones < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    remove_column :milestone_releases, :id, :bigint
  end
end
