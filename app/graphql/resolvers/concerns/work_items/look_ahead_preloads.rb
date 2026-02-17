# frozen_string_literal: true

module WorkItems
  module LookAheadPreloads
    extend ActiveSupport::Concern

    prepended do
      include ::LooksAhead
    end

    private

    def preloads
      {
        author: [:author],
        [:author, :gitpod_enabled] => { author: :user_preference },
        [:author, :location] => { author: :user_detail },
        archived: {
          namespace: :namespace_settings_with_ancestors_inherited_settings,
          project: { namespace: :namespace_settings_with_ancestors_inherited_settings }
        },
        [:project, :jira_import_status] => { project: :jira_imports },
        [:user_permissions, :update_work_item] => :assignees,
        web_url: { namespace: :route, project: [:project_namespace, {
          namespace: [:route, :namespace_settings_with_ancestors_inherited_settings]
        }] },
        widgets: { work_item_type: :enabled_widget_definitions },
        work_item_type: :work_item_type
      }.merge!(widget_preloads)
    end

    def widget_preloads
      {
        [:widgets, :assignees] => :assignees_by_name_and_id,
        [:widgets, :award_emoji] => { award_emoji: :awardable },
        [:widgets, :children] => { work_item_children_by_relative_position: [:author, { project: :project_feature }] },
        [:widgets, :closing_merge_requests] => {
          merge_requests_closing_issues: { merge_request: [:target_project, :author] }
        },
        [:widgets, :due_date] => :dates_source,
        [:widgets, :has_parent] => :work_item_parent,
        [:widgets, :last_edited_by] => :last_edited_by,
        [:widgets, :milestone] => { milestone: [:project, :group] },
        [:widgets, :parent] => :work_item_parent,
        [:widgets, :participants] => WorkItem.participant_includes,
        [:widgets, :start_date] => :dates_source,
        [:widgets, :subscribed] => [:assignees, :award_emoji, { notes: [:author, :award_emoji] }]
      }
    end

    def unconditional_includes
      [
        {
          project: [:project_feature, :group]
        },
        :author,
        :work_item_type,
        *super
      ]
    end
  end
end

WorkItems::LookAheadPreloads.prepend_mod
