module Integrations
  class MergeRequestService < BaseService

    private

    def klass
      MergeRequest
    end

    def collection
      klass.where(target_project: project)
    end

    def title(merge_request)
      format("!#{merge_request.iid} #{merge_request.title}")
    end

    def link(merge_request)
      Gitlab::Routing.url_helpers.namespace_project_merge_request_url(project.namespace,
                                                                      project,
                                                                      merge_request)
    end
  end
end
