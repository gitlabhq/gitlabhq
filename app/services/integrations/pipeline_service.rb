module Integrations
  class PipelineService < BaseService

    def execute
      resource =
        if resource_id
          merge_request_pipeline(resource_id)
        else
          pipeline_by_ref(params[:text])
        end

      generate_response(resource)
    end

    private

    def merge_request_pipeline(iid)
      project.merge_requests.find_by(iid: iid).pipeline
    end

    def pipeline_by_ref(ref)
      project.pipelines.where(ref: ref).last
    end

    def klass
      Pipeline
    end

    def title(pipeline)
      "##{pipeline.id} Pipeline for #{pipeline.ref}: #{pipeline.status}"
    end

    def link(pipeline)
      Gitlab::Routing.url_helpers.namespace_project_pipeline_url(project.namespace,
                                                                 project,
                                                                 pipeline)
    end

    def large_attachment(pipeline)
      {
        fallback: title(pipeline),
        title: title(pipeline),
        title_link: link(pipeline),
        color: "#C95823"
      }
    end
  end
end
