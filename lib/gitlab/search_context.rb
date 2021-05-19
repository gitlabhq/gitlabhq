# frozen_string_literal: true

module Gitlab
  # Holds the contextual data used by navbar search component to
  # determine the search scope, whether to search for code, or if
  # a search should target snippets.
  #
  # Use the SearchContext::Builder to create an instance of this class
  class SearchContext
    attr_accessor :project, :project_metadata, :ref,
                  :group, :group_metadata,
                  :snippets,
                  :scope, :search_url

    def initialize
      @ref = nil
      @project = nil
      @project_metadata = {}
      @group = nil
      @group_metadata = {}
      @snippets = []
      @scope = nil
      @search_url = nil
    end

    def for_project?
      project.present? && project.persisted?
    end

    def for_group?
      group.present? && group.persisted?
    end

    def for_snippets?
      snippets.any?
    end

    def code_search?
      project.present? && scope.nil?
    end

    class Builder
      def initialize(view_context)
        @view_context = view_context
        @snippets = []
      end

      def with_snippet(snippet)
        @snippets << snippet

        self
      end

      def with_project(project)
        @project = project
        with_group(project&.group)

        self
      end

      def with_group(group)
        @group = group

        self
      end

      def with_ref(ref)
        @ref = ref

        self
      end

      def build!
        SearchContext.new.tap do |context|
          context.project = @project
          context.group = @group
          context.ref = @ref
          context.snippets = @snippets.dup
          context.scope = search_scope
          context.search_url = search_url
          context.group_metadata = group_search_metadata(@group)
          context.project_metadata = project_search_metadata(@project)
        end
      end

      private

      attr_accessor :view_context

      def project_search_metadata(project)
        return {} unless project

        {
          project_path: project.path,
          name: project.name,
          issues_path: view_context.project_issues_path(project),
          mr_path: view_context.project_merge_requests_path(project),
          issues_disabled: !project.issues_enabled?
        }
      end

      def group_search_metadata(group)
        return {} unless group

        {
          group_path: group.path,
          name: group.name,
          issues_path: view_context.issues_group_path(group),
          mr_path: view_context.merge_requests_group_path(group)
        }
      end

      def search_url
        if @project.present?
          view_context.search_path(project_id: @project.id)
        elsif @group.present?
          view_context.search_path(group_id: @group.id)
        else
          view_context.search_path
        end
      end

      def search_scope
        if view_context.current_controller?(:issues)
          'issues'
        elsif view_context.current_controller?(:merge_requests)
          'merge_requests'
        elsif view_context.current_controller?(:wikis)
          'wiki_blobs'
        elsif view_context.current_controller?(:commits)
          'commits'
        elsif view_context.current_controller?(:groups)
          if %w(issues merge_requests).include?(view_context.controller.action_name)
            view_context.controller.action_name
          end
        end
      end
    end

    module ControllerConcern
      extend ActiveSupport::Concern

      included do
        helper_method :search_context
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      #
      # Introspect the current controller's assignments and
      # and builds the proper SearchContext object for it.
      def search_context
        builder = Builder.new(view_context)

        builder.with_snippet(@snippet) if @snippet.present?
        @snippets.each(&builder.method(:with_snippet)) if @snippets.present?
        builder.with_project(@project) if @project.present? && @project.persisted?
        builder.with_group(@group) if @group.present? && @group.persisted?
        builder.with_ref(@ref) if @ref.present?

        builder.build!
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end

Gitlab::SearchContext::Builder.prepend_mod
