# frozen_string_literal: true

module Ci
  class ProjectMetric < Ci::ApplicationRecord
    KNOWN_AGENT_SOURCES = %w[
      ci_expert_agent/v1
    ].freeze

    belongs_to :project

    validates :ci_config_generated_by, length: { maximum: 255 }, allow_nil: true

    def self.first_pipeline_success_recorded?(project_id)
      where(project_id: project_id).where.not(first_pipeline_succeeded_at: nil).exists?
    end

    def self.record_first_pipeline_success!(project_id, timestamp = Time.current)
      upsert(
        { project_id: project_id, first_pipeline_succeeded_at: timestamp },
        unique_by: :project_id
      )
    end

    def self.ci_config_generated_by_for(project_id)
      where(project_id: project_id).pick(:ci_config_generated_by)
    end

    def self.ai_pipeline_results_trackable?(project_id)
      where(project_id: project_id)
        .where.not(ci_config_generated_by: nil)
        .where.not(ci_config_first_generated_at: nil)
        .where(first_ai_pipeline_results_viewed_at: nil)
        .exists?
    end

    def self.mark_ai_pipeline_results_viewed(project_id, pipeline_created_at, viewed_at = Time.current)
      where(project_id: project_id)
        .where.not(ci_config_generated_by: nil)
        .where.not(ci_config_first_generated_at: nil)
        .where(first_ai_pipeline_results_viewed_at: nil)
        .where(ci_config_first_generated_at: ..pipeline_created_at)
        .update_all(first_ai_pipeline_results_viewed_at: viewed_at, updated_at: viewed_at)
    end

    def self.track_ai_generated_config!(project_id, author_source:)
      return unless author_source.in?(KNOWN_AGENT_SOURCES)

      upsert(
        { project_id: project_id, ci_config_generated_by: author_source, ci_config_first_generated_at: Time.current },
        unique_by: :project_id,
        on_duplicate: Arel.sql(<<~SQL.squish)
          ci_config_generated_by = EXCLUDED.ci_config_generated_by,
          ci_config_first_generated_at = COALESCE(ci_project_metrics.ci_config_first_generated_at, EXCLUDED.ci_config_first_generated_at),
          updated_at = EXCLUDED.updated_at
        SQL
      )
    end
  end
end
