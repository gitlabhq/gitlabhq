# frozen_string_literal: true

module Gitlab
  class UrlBuilder
    include Singleton
    include Gitlab::Routing
    include GitlabRoutingHelper

    delegate :build, to: :class

    class << self
      include ActionView::RecordIdentifier

      def build(object, **options)
        # Objects are sometimes wrapped in a BatchLoader instance
        case object.itself
        when ::Ci::Build
          instance.project_job_url(object.project, object, **options)
        when Commit
          commit_url(object, **options)
        when Group
          instance.group_canonical_url(object, **options)
        when Issue
          instance.issue_url(object, **options)
        when MergeRequest
          instance.merge_request_url(object, **options)
        when Milestone
          instance.milestone_url(object, **options)
        when Note
          note_url(object, **options)
        when Project
          instance.project_url(object, **options)
        when Snippet
          snippet_url(object, **options)
        when User
          instance.user_url(object, **options)
        when Wiki
          wiki_url(object, **options)
        when WikiPage
          instance.project_wiki_url(object.wiki.project, object.slug, **options)
        else
          raise NotImplementedError.new("No URL builder defined for #{object.inspect}")
        end
      end

      def commit_url(commit, **options)
        return '' unless commit.project

        instance.commit_url(commit, **options)
      end

      def note_url(note, **options)
        if note.for_commit?
          return '' unless note.project

          instance.project_commit_url(note.project, note.commit_id, anchor: dom_id(note), **options)
        elsif note.for_issue?
          instance.issue_url(note.noteable, anchor: dom_id(note), **options)
        elsif note.for_merge_request?
          instance.merge_request_url(note.noteable, anchor: dom_id(note), **options)
        elsif note.for_snippet?
          instance.gitlab_snippet_url(note.noteable, anchor: dom_id(note), **options)
        end
      end

      def snippet_url(snippet, **options)
        if options.delete(:raw).present?
          instance.gitlab_raw_snippet_url(snippet, **options)
        else
          instance.gitlab_snippet_url(snippet, **options)
        end
      end

      def wiki_url(object, **options)
        case object.container
        when Project
          instance.project_wiki_url(object.container, Wiki::HOMEPAGE, **options)
        when Group
          # TODO: Use the new route for group wikis once we add it.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/211360
          instance.group_canonical_url(object.container, **options) + "/-/wikis/#{Wiki::HOMEPAGE}"
        else
          raise NotImplementedError.new("No URL builder defined for #{object.inspect}")
        end
      end
    end
  end
end

::Gitlab::UrlBuilder.prepend_if_ee('EE::Gitlab::UrlBuilder')
