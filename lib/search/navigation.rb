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
      nav = {
        projects: {
          sort: 1,
          label: _("Projects"),
          data: { testid: 'projects-tab' },
          condition: project.nil?
        },
        blobs: {
          sort: 2,
          label: _("Code"),
          data: { testid: 'code-tab' },
          condition: show_code_search_tab?
        },
        #  sort: 3 is reserved for EE items
        issues: {
          sort: 4,
          label: _("Issues"),
          condition: show_issues_search_tab?
        },
        merge_requests: {
          sort: 5,
          label: _("Merge requests"),
          condition: show_merge_requests_search_tab?
        },
        wiki_blobs: {
          sort: 6,
          label: _("Wiki"),
          condition: show_wiki_search_tab?
        },
        commits: {
          sort: 7,
          label: _("Commits"),
          condition: show_commits_search_tab?
        },
        notes: {
          sort: 8,
          label: _("Comments"),
          condition: show_comments_search_tab?
        },
        milestones: {
          sort: 9, label: _("Milestones"),
          condition: show_milestones_search_tab?
        },
        users: {
          sort: 10,
          label: _("Users"),
          condition: show_user_search_tab?
        },
        snippet_titles: {
          sort: 11,
          label: _("Snippets"),
          search: { snippets: true, group_id: nil, project_id: nil },
          condition: show_snippets_search_tab?
        }
      }

      return nav unless ::Feature.enabled?(:work_item_scope_frontend, user)

      nav[:issues] = {
        sort: 4,
        label: _("Work items"),
        sub_items: get_sub_items,
        condition: show_issues_search_tab?
      }

      nav
    end

    private

    def get_sub_items
      ::WorkItems::Type::TYPE_NAMES.each_with_object({}) do |(key, value, index), hash|
        next if key.to_s == 'epic'

        hash[key] ||= {}
        hash[key][:scope] = 'issues'
        hash[key][:label] = value
        hash[key][:type] = key
        hash[key][:sort] = index
        hash[key][:active] = ''
        hash[key][:condition] = show_issues_search_tab?
      end
    end

    attr_reader :user, :project, :group, :options

    def show_elasticsearch_tabs?
      !!options[:show_elasticsearch_tabs]
    end

    def search_tab_ability_map
      {
        milestones: :read_milestone,
        snippets: :read_snippet,
        issues: :read_issue,
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
      return true if tab_enabled_for_project?(:notes)

      project.nil? && show_elasticsearch_tabs?
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
