# frozen_string_literal: true

class AddPlanLimitsForMaxSizePerArtifactType < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    # We need to set the 20mb default for lsif for backward compatibility
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34767#note_371619075
    add_column :plan_limits, "ci_max_artifact_size_lsif", :integer, default: 20, null: false

    artifact_types.each do |type|
      add_column :plan_limits, "ci_max_artifact_size_#{type}", :integer, default: 0, null: false
    end
  end

  private

  def artifact_types
    # The list of artifact types (except lsif) from Ci::JobArtifact file_type enum as of this writing.
    # Intentionally duplicated so that the migration won't change behavior
    # if ever we remove or add more to the list later on.
    %w[
      archive
      metadata
      trace
      junit
      sast
      dependency_scanning
      container_scanning
      dast
      codequality
      license_management
      license_scanning
      performance
      metrics
      metrics_referee
      network_referee
      dotenv
      cobertura
      terraform
      accessibility
      cluster_applications
      secret_detection
      requirements
      coverage_fuzzing
    ]
  end
end
