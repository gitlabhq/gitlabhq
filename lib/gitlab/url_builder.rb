# frozen_string_literal: true

module Gitlab
  class UrlBuilder
    include Singleton
    include Gitlab::Routing
    include GitlabRoutingHelper

    delegate :build, to: :class

    class << self
      include ActionView::RecordIdentifier

      # Using a case statement here is preferable for readability and maintainability.
      # See discussion in https://gitlab.com/gitlab-org/gitlab/-/issues/217397
      #
      # rubocop:disable Metrics/CyclomaticComplexity
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
          wiki_page_url(object, Wiki::HOMEPAGE, **options)
        when WikiPage
          wiki_page_url(object.wiki, object, **options)
        when ::DesignManagement::Design
          design_url(object, **options)
        else
          raise NotImplementedError.new("No URL builder defined for #{object.inspect}")
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

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

      def wiki_page_url(wiki, page, **options)
        if wiki.container.is_a?(Project)
          instance.project_wiki_url(wiki.container, page, **options)
        else
          raise NotImplementedError.new("No URL builder defined for #{wiki.container.inspect} wikis")
        end
      end

      def design_url(design, **options)
        size, ref = options.values_at(:size, :ref)
        options.except!(:size, :ref)

        if size
          instance.project_design_management_designs_resized_image_url(design.project, design, ref, size, **options)
        else
          instance.project_design_management_designs_raw_image_url(design.project, design, ref, **options)
        end
      end
    end
  end
end

::Gitlab::UrlBuilder.prepend_if_ee('EE::Gitlab::UrlBuilder')
