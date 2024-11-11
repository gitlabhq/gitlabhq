# frozen_string_literal: true

module Ci
  class ExpirePipelineCacheService
    class UrlHelpers
      include ::Gitlab::Routing
      include ::GitlabRoutingHelper
    end

    def execute(pipeline, delete: false)
      store = Gitlab::EtagCaching::Store.new

      update_etag_cache(pipeline, store)

      if delete
        Gitlab::Cache::Ci::ProjectPipelineStatus.new(pipeline.project).delete_from_cache
      else
        Gitlab::Cache::Ci::ProjectPipelineStatus.update_for_pipeline(pipeline)
      end
    end

    private

    def project_pipelines_path(project)
      url_helpers.project_pipelines_path(project, format: :json)
    end

    def project_pipeline_path(project, pipeline)
      url_helpers.project_pipeline_path(project, pipeline, format: :json)
    end

    def commit_pipelines_path(project, commit)
      url_helpers.pipelines_project_commit_path(project, commit.id, format: :json)
    end

    def new_merge_request_pipelines_path(project)
      url_helpers.project_new_merge_request_path(project, format: :json)
    end

    def pipelines_project_merge_request_path(merge_request)
      url_helpers.pipelines_project_merge_request_path(merge_request.target_project, merge_request, format: :json)
    end

    def merge_request_widget_path(merge_request)
      url_helpers.cached_widget_project_json_merge_request_path(merge_request.project, merge_request, format: :json)
    end

    def each_pipelines_merge_request_path(pipeline)
      pipeline.all_merge_requests.each do |merge_request|
        yield(pipelines_project_merge_request_path(merge_request))
        yield(merge_request_widget_path(merge_request))
      end

      pipeline.project.merge_requests.by_merged_or_merge_or_squash_commit_sha(pipeline.sha).each do |merge_request|
        yield(merge_request_widget_path(merge_request))
      end
    end

    def graphql_pipeline_path(pipeline)
      url_helpers.graphql_etag_pipeline_path(pipeline)
    end

    def graphql_pipeline_sha_path(sha)
      url_helpers.graphql_etag_pipeline_sha_path(sha)
    end

    def graphql_project_on_demand_scan_counts_path(project)
      url_helpers.graphql_etag_project_on_demand_scan_counts_path(project)
    end

    # Updates ETag caches of a pipeline.
    #
    # This logic resides in a separate method so that EE can more easily extend
    # it.
    #
    # @param [Ci::Pipeline] pipeline
    # @param [Gitlab::EtagCaching::Store] store
    def update_etag_cache(pipeline, store)
      project = pipeline.project

      etag_paths = [
        project_pipelines_path(project),
        new_merge_request_pipelines_path(project),
        graphql_project_on_demand_scan_counts_path(project)
      ]

      etag_paths << commit_pipelines_path(project, pipeline.commit) if pipeline.sha && pipeline.commit.present?

      each_pipelines_merge_request_path(pipeline) do |path|
        etag_paths << path
      end

      pipeline.upstream_and_all_downstreams.includes(project: [:route, { namespace: :route }]).each do |relative_pipeline| # rubocop: disable CodeReuse/ActiveRecord
        etag_paths << project_pipeline_path(relative_pipeline.project, relative_pipeline)
        etag_paths << graphql_pipeline_path(relative_pipeline)
        etag_paths << graphql_pipeline_sha_path(relative_pipeline.sha) if relative_pipeline.sha
      end

      store.touch(*etag_paths)
    end

    def url_helpers
      @url_helpers ||= UrlHelpers.new
    end
  end
end
