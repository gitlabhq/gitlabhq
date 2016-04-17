module Gitlab
  class UrlBuilder
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper
    include ActionView::RecordIdentifier

    attr_reader :object

    def self.build(object)
      new(object).url
    end

    def url
      case object
      when Commit
        commit_url
      when Issue
        issue_url(object)
      when MergeRequest
        merge_request_url(object)
      when Note
        note_url
      else
        raise NotImplementedError.new("No URL builder defined for #{object.class}")
      end
    end

    private

    def initialize(object)
      @object = object
    end

    def commit_url(opts = {})
      return '' if object.project.nil?

      namespace_project_commit_url({
        namespace_id: object.project.namespace,
        project_id: object.project,
        id: object.id
      }.merge!(opts))
    end

    def note_url
      if object.for_commit?
        commit_url(id: object.commit_id, anchor: dom_id(object))

      elsif object.for_issue?
        issue = Issue.find(object.noteable_id)
        issue_url(issue, anchor: dom_id(object))

      elsif object.for_merge_request?
        merge_request = MergeRequest.find(object.noteable_id)
        merge_request_url(merge_request, anchor: dom_id(object))

      elsif object.for_snippet?
        snippet = Snippet.find(object.noteable_id)
        project_snippet_url(snippet, anchor: dom_id(object))
      end
    end
  end
end
