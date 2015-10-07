module Gitlab
  class UrlBuilder
    include Gitlab::Application.routes.url_helpers
    include GitlabRoutingHelper

    def initialize(type)
      @type = type
    end

    def build(id)
      case @type
      when :issue
        build_issue_url(id)
      when :merge_request
        build_merge_request_url(id)
      when :note
        build_note_url(id)

      end
    end

    private

    def build_issue_url(id)
      issue = Issue.find(id)
      issue_url(issue)
    end

    def build_merge_request_url(id)
      merge_request = MergeRequest.find(id)
      merge_request_url(merge_request)
    end

    def build_note_url(id)
      note = Note.find(id)
      if note.for_commit?
        namespace_project_commit_url(namespace_id: note.project.namespace,
                                     id: note.commit_id,
                                     project_id: note.project,
                                     anchor: "note_#{note.id}")
      elsif note.for_issue?
        issue = Issue.find(note.noteable_id)
        issue_url(issue,
                  anchor: "note_#{note.id}")
      elsif note.for_merge_request?
        merge_request = MergeRequest.find(note.noteable_id)
        merge_request_url(merge_request,
                          anchor: "note_#{note.id}")
      elsif note.for_project_snippet?
        snippet = Snippet.find(note.noteable_id)
        project_snippet_url(snippet,
                            anchor: "note_#{note.id}")
      end
    end
  end
end
