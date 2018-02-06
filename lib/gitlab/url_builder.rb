module Gitlab
  class UrlBuilder
    include Gitlab::Routing
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
      when WikiPage
        wiki_page_url
      when ProjectSnippet
        project_snippet_url(object.project, object)
      when Snippet
        snippet_url(object)
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
        issue_url(object.noteable, anchor: dom_id(object))

      elsif object.for_merge_request?
        merge_request_url(object.noteable, anchor: dom_id(object))

      elsif object.for_snippet?
        snippet = object.noteable

        if snippet.is_a?(PersonalSnippet)
          snippet_url(snippet, anchor: dom_id(object))
        else
          project_snippet_url(snippet.project, snippet, anchor: dom_id(object))
        end
      end
    end

    def wiki_page_url
      project_wiki_url(object.wiki.project, object.slug)
    end
  end
end
