# frozen_string_literal: true

module Ci
  # A state object to centralize logic related to merge request pipelines
  class PipelinesForMergeRequestFinder
    include Gitlab::Utils::StrongMemoize

    def initialize(merge_request, current_user)
      @merge_request = merge_request
      @current_user = current_user
    end

    attr_reader :merge_request, :current_user

    delegate :commit_shas, :target_project, :source_project, :source_branch, to: :merge_request

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
            pipelines_using_cte
          else
            triggered_for_branch.for_sha(commit_shas)
          end

        sort(pipelines)
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def pipelines_using_cte
      sha_relation = merge_request.all_commits.select(:sha).distinct

      cte = Gitlab::SQL::CTE.new(:shas, sha_relation)

      pipelines_for_merge_requests = triggered_by_merge_request
      pipelines_for_branch = filter_by_sha(triggered_for_branch, cte)

      Ci::Pipeline.with(cte.to_arel) # rubocop: disable CodeReuse/ActiveRecord
        .from_union([pipelines_for_merge_requests, pipelines_for_branch])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def filter_by_sha(pipelines, cte)
      hex = Arel::Nodes::SqlLiteral.new("'hex'")
      string_sha = Arel::Nodes::NamedFunction.new('encode', [cte.table[:sha], hex])
      join_condition = string_sha.eq(Ci::Pipeline.arel_table[:sha])

      filter_by(pipelines, cte, join_condition)
    end

    def filter_by(pipelines, cte, join_condition)
      shas_table =
        Ci::Pipeline.arel_table
          .join(cte.table, Arel::Nodes::InnerJoin)
          .on(join_condition)
          .join_sources

      pipelines.joins(shas_table) # rubocop: disable CodeReuse/ActiveRecord
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
      sql = 'CASE ci_pipelines.source WHEN (?) THEN 0 ELSE 1 END, ci_pipelines.id DESC'
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
