# frozen_string_literal: true

class AddExpireAtToCiPipelineArtifact < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :ci_pipeline_artifacts, :expire_at, :datetime_with_timezone
  end
end
