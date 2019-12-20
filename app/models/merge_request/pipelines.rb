# frozen_string_literal: true

# A state object to centralize logic related to merge request pipelines
class MergeRequest::Pipelines
  include Gitlab::Utils::StrongMemoize

  EVENT = 'merge_request_event'

  def initialize(merge_request)
    @merge_request = merge_request
  end

  attr_reader :merge_request

  delegate :commit_shas, :source_project, :source_branch, to: :merge_request

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

  def pipelines_using_cte
    cte = Gitlab::SQL::CTE.new(:shas, merge_request.all_commits.select(:sha))

    source_pipelines_join = cte.table[:sha].eq(Ci::Pipeline.arel_table[:source_sha])
    source_pipelines = filter_by(triggered_by_merge_request, cte, source_pipelines_join)
    detached_pipelines = filter_by_sha(triggered_by_merge_request, cte)
    pipelines_for_branch = filter_by_sha(triggered_for_branch, cte)

    Ci::Pipeline.with(cte.to_arel)
      .from_union([source_pipelines, detached_pipelines, pipelines_for_branch])
  end

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

    pipelines.joins(shas_table)
  end

  def triggered_by_merge_request
    source_project.ci_pipelines
      .where(source: :merge_request_event, merge_request: merge_request)
  end

  def triggered_for_branch
    source_project.ci_pipelines
      .where(source: branch_pipeline_sources, ref: source_branch, tag: false)
  end

  def branch_pipeline_sources
    strong_memoize(:branch_pipeline_sources) do
      Ci::Pipeline.sources.reject { |source| source == EVENT }.values
    end
  end

  def sort(pipelines)
    sql = 'CASE ci_pipelines.source WHEN (?) THEN 0 ELSE 1 END, ci_pipelines.id DESC'
    query = ApplicationRecord.send(:sanitize_sql_array, [sql, Ci::Pipeline.sources[:merge_request_event]]) # rubocop:disable GitlabSecurity/PublicSend

    pipelines.order(Arel.sql(query))
  end
end
