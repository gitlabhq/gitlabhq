module Integrations
  class MergeRequestService < Integrations::BaseService
    private

    def collection
      project.merge_requests
    end

    def link(merge_request)
      Gitlab::Routing.
        url_helpers
        .namespace_project_merge_request_url(project.namespace, project, merge_request)
    end
  end
end
