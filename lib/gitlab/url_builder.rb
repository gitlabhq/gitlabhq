# frozen_string_literal: true

module Gitlab
  class UrlBuilder
    include Gitlab::Routing
    include GitlabRoutingHelper
    include ActionView::RecordIdentifier

    attr_reader :object, :opts

    def self.build(object, opts = {})
      new(object, opts).url
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
      when Snippet
        opts[:raw].present? ? gitlab_raw_snippet_url(object) : gitlab_snippet_url(object)
      when Milestone
        milestone_url(object)
      when ::Ci::Build
        project_job_url(object.project, object)
      when User
        user_url(object)
      else
        raise NotImplementedError.new("No URL builder defined for #{object.class}")
      end
    end

    private

    def initialize(object, opts = {})
      @object = object
      @opts = opts
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
        gitlab_snippet_url(object.noteable, anchor: dom_id(object))
      end
    end

    def wiki_page_url
      project_wiki_url(object.wiki.project, object.slug)
    end
  end
end

::Gitlab::UrlBuilder.prepend_if_ee('EE::Gitlab::UrlBuilder')
