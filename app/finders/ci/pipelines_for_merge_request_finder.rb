# frozen_string_literal: true

module Ci
  # A state object to centralize logic related to merge request pipelines
  class PipelinesForMergeRequestFinder
    include Gitlab::Utils::StrongMemoize

    COMMITS_LIMIT = 100

    def initialize(merge_request, current_user)
      @merge_request = merge_request
      @current_user = current_user
    end

    attr_reader :merge_request, :current_user

    delegate :recent_diff_head_shas, :commit_shas, :target_project, :source_project, :source_branch, to: :merge_request

    # Fetch all pipelines that the user can read.
    def execute
      if can_read_pipeline_in_target_project? && can_read_pipeline_in_source_project?
        all
      elsif can_read_pipeline_in_source_project?
        all.for_project(merge_request.source_project)
      elsif can_read_pipeline_in_target_project?
        all.for_project(merge_request.target_project)
      else
        Ci::Pipeline.none
      end
    end

    # Fetch all pipelines without permission check.
    def all
      strong_memoize(:all_pipelines) do
        next Ci::Pipeline.none unless source_project

        pipelines =
          if merge_request.persisted?
            all_pipelines_for_merge_request
          else
            triggered_for_branch.for_sha(commit_shas)
          end

        sort(pipelines)
      end
    end

    private

    def all_pipelines_for_merge_request
      pipelines_for_merge_request = triggered_by_merge_request
      pipelines_for_branch = triggered_for_branch.for_sha(recent_diff_head_shas(COMMITS_LIMIT))

      Ci::Pipeline.from_union([pipelines_for_merge_request, pipelines_for_branch])
    end

    # NOTE: this method returns only parent merge request pipelines.
    # Child merge request pipelines have a different source.
    def triggered_by_merge_request
      Ci::Pipeline.triggered_by_merge_request(merge_request)
    end

    def triggered_for_branch
      source_project.all_pipelines.ci_branch_sources.for_branch(source_branch)
    end

    def sort(pipelines)
      pipelines_table = Ci::Pipeline.quoted_table_name
      sql = "CASE #{pipelines_table}.source WHEN (?) THEN 0 ELSE 1 END, #{pipelines_table}.id DESC"
      query = ApplicationRecord.send(:sanitize_sql_array, [sql, Ci::Pipeline.sources[:merge_request_event]]) # rubocop:disable GitlabSecurity/PublicSend

      pipelines.order(Arel.sql(query)) # rubocop: disable CodeReuse/ActiveRecord
    end

    def can_read_pipeline_in_target_project?
      strong_memoize(:can_read_pipeline_in_target_project) do
        Ability.allowed?(current_user, :read_pipeline, target_project)
      end
    end

    def can_read_pipeline_in_source_project?
      strong_memoize(:can_read_pipeline_in_source_project) do
        Ability.allowed?(current_user, :read_pipeline, source_project)
      end
    end
  end
end
