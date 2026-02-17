# frozen_string_literal: true

module Search
  class Navigation
    include Gitlab::Allowable

    def initialize(user:, project: nil, group: nil, options: {})
      @user = user
      @project = project
      @group = group
      @options = options
    end

    def tab_enabled_for_project?(tab)
      return false unless project.present?

      abilities = Array(search_tab_ability_map[tab])
      Array.wrap(project).any? { |p| abilities.any? { |ability| can?(user, ability, p) } }
    end

    def tabs
      nav = {}
      Search::Scopes.scope_definitions.each do |scope_key, definition|
        label = definition[:label]
        label = label.call if label.respond_to?(:call)

        nav[scope_key] = {
          sort: definition[:sort],
          label: label,
          condition: scope_visible?(scope_key)
        }

        # Only add data attribute for projects and blobs (to match legacy behavior)
        if scope_key == :projects
          nav[scope_key][:data] = { testid: 'projects-tab' }
        elsif scope_key == :blobs
          nav[scope_key][:data] = { testid: 'code-tab' }
        end

        nav[scope_key][:search] = { snippets: true, group_id: nil, project_id: nil } if scope_key == :snippet_titles
      end

      nav
    end

    private

    # Returns whether a scope should be visible
    # This method is called for each scope defined in Search::Scopes::SCOPE_DEFINITIONS
    def scope_visible?(scope_key)
      case scope_key
      when :projects
        project.nil?
      when :blobs
        show_code_search_tab?
      when :issues
        show_issues_search_tab?
      when :merge_requests
        show_merge_requests_search_tab?
      when :wiki_blobs
        show_wiki_search_tab?
      when :commits
        show_commits_search_tab?
      when :notes
        show_comments_search_tab?
      when :milestones
        show_milestones_search_tab?
      when :users
        show_user_search_tab?
      else # scope_key is restricted to predefined keys; safe to use else
        show_snippets_search_tab?
      end
    end

    attr_reader :user, :project, :group, :options

    def search_tab_ability_map
      {
        milestones: :read_milestone,
        snippets: :read_snippet,
        issues: :read_issue,
        work_items: :read_issue,
        blobs: :read_code,
        commits: :read_code,
        merge_requests: :read_merge_request,
        notes: [:read_merge_request, :read_code, :read_issue, :read_snippet],
        users: :read_project_member,
        wiki_blobs: :read_wiki
      }
    end

    def show_user_search_tab?
      return true if tab_enabled_for_project?(:users)
      return false unless can?(user, :read_users_list)

      project.nil? && (group.present? || ::Gitlab::CurrentSettings.global_search_users_enabled?)
    end

    def show_code_search_tab?
      tab_enabled_for_project?(:blobs)
    end

    def show_wiki_search_tab?
      tab_enabled_for_project?(:wiki_blobs)
    end

    def show_commits_search_tab?
      tab_enabled_for_project?(:commits)
    end

    def show_issues_search_tab?
      return true if tab_enabled_for_project?(:issues)

      project.nil? && (group.present? || ::Gitlab::CurrentSettings.global_search_issues_enabled?)
    end

    def show_merge_requests_search_tab?
      return true if tab_enabled_for_project?(:merge_requests)

      project.nil? && (group.present? || ::Gitlab::CurrentSettings.global_search_merge_requests_enabled?)
    end

    def show_comments_search_tab?
      tab_enabled_for_project?(:notes)
    end

    def show_snippets_search_tab?
      !!options[:show_snippets] && project.nil? &&
        (group.present? || ::Gitlab::CurrentSettings.global_search_snippet_titles_enabled?)
    end

    def show_milestones_search_tab?
      project.nil? || tab_enabled_for_project?(:milestones)
    end
  end
end

Search::Navigation.prepend_mod
