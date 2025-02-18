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
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def build(object, **options)
        # Objects are sometimes wrapped in a BatchLoader instance
        case object.itself
        when Board
          board_url(object, **options)
        when ::Ci::Build
          instance.project_job_url(object.project, object, **options)
        when ::Ci::Pipeline
          instance.project_pipeline_url(object.project, object, **options)
        when Commit
          commit_url(object, **options)
        when Compare
          compare_url(object, **options)
        when Group
          instance.group_canonical_url(object, **options)
        when WorkItem
          instance.work_item_url(object, **options)
        when Issue
          instance.issue_url(object, **options)
        when MergeRequest
          instance.merge_request_url(object, **options)
        when Milestone
          instance.milestone_url(object, **options)
        when Note
          note_url(object, **options)
        when AntiAbuse::Reports::Note
          abuse_report_note_url(object, **options)
        when Release
          instance.release_url(object, **options)
        when ::Organizations::Organization
          instance.organization_url(object, **options)
        when Project
          instance.project_url(object, **options)
        when Snippet
          snippet_url(object, **options)
        when User
          instance.user_url(object, **options)
        when Namespaces::UserNamespace
          instance.user_url(object.owner, **options)
        when Namespaces::ProjectNamespace
          instance.project_url(object.project, **options)
        when Wiki
          wiki_url(object, **options)
        when WikiPage
          wiki_page_url(object.wiki, object, **options)
        when WikiPage::Meta
          wiki_page_url(object.container.wiki, object.canonical_slug, **options)
        when ::DesignManagement::Design
          design_url(object, **options)
        when ::Packages::Package
          package_url(object, **options)
        when ::Key
          instance.user_settings_ssh_key_url(object)
        else
          raise NotImplementedError, "No URL builder defined for #{object.inspect}"
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity

      def board_url(board, **options)
        if board.project_board?
          instance.project_board_url(board.resource_parent, board, **options)
        else
          instance.group_board_url(board.resource_parent, board, **options)
        end
      end

      def commit_url(commit, **options)
        return '' unless commit.project

        instance.commit_url(commit, **options)
      end

      def compare_url(compare, **options)
        return '' unless compare.project

        instance.project_compare_url(compare.project, **options.merge(compare.to_param))
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
        elsif note.for_abuse_report?
          instance.admin_abuse_report_url(note.noteable, anchor: dom_id(note), **options)
        elsif note.for_wiki_page?
          instance.project_wiki_page_url(note.noteable, anchor: dom_id(note), **options)
        end
      end

      def abuse_report_note_url(note, **options)
        instance.admin_abuse_report_url(note.abuse_report, anchor: dom_id(note), **options)
      end

      def snippet_url(snippet, **options)
        if options[:file].present?
          file, ref = options.values_at(:file, :ref)

          instance.gitlab_raw_snippet_blob_url(snippet, file, ref)
        elsif options.delete(:raw).present?
          instance.gitlab_raw_snippet_url(snippet, **options)
        else
          instance.gitlab_snippet_url(snippet, **options)
        end
      end

      def wiki_url(wiki, **options)
        return wiki_page_url(wiki, Wiki::HOMEPAGE, **options) unless options[:action]

        if wiki.container.is_a?(Project)
          options[:controller] = 'projects/wikis'
          options[:namespace_id] = wiki.container.namespace
          options[:project_id] = wiki.container
        end

        instance.url_for(**options)
      end

      def wiki_page_url(wiki, page, **options)
        options[:action] ||= :show
        options[:id] = page

        wiki_url(wiki, **options)
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

      def package_url(package, **options)
        project = package.project

        if package.terraform_module?
          return instance.project_infrastructure_registry_url(project, package,
**options)
        end

        instance.project_package_url(project, package, **options)
      end
    end
  end
end

::Gitlab::UrlBuilder.prepend_mod_with('Gitlab::UrlBuilder')
