module Integrations
  class PipelineService < Integrations::BaseService
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
      project.merge_requests.find_by(iid: iid).try(:pipeline)
    end

    def pipeline_by_ref(ref)
      project.pipelines.where(ref: ref).last
    end

    def title(pipeline)
      "Pipeline for #{pipeline.ref}: #{pipeline.status}"
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
        fields: [
          fields(pipeline)
        ]
      }
    end

    def fields(pipeline)
      commit = pipeline.commit

      return [] unless commit

      [
        {
          title: 'Author',
          value: commit.author.name,
          short: true
        },
        {
          title: 'Commit Title',
          value: commit.title,
          short: true
        }
      ]
    end
  end
end
