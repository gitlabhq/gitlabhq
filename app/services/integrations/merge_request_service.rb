module Integrations
  class MergeRequestService < BaseService

    private

    def klass
      MergeRequest
    end

    def title(merge_request)
      "[!#{merge_request.iid} #{merge_request.title}](#{link(merge_request)})"
    end

    def link(merge_request)
      Gitlab::Routing.url_helpers.namespace_project_merge_request_url(project.namespace,
                                                                      project,
                                                                      merge_request)
    end

    def find_resource
      collection.find_by(iid: params[:text])
    end
  end
end
