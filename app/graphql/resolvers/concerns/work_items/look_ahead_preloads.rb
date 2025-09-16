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
        work_item_type: :work_item_type,
        web_url: { namespace: :route, project: [:project_namespace, {
          namespace: [:route, :namespace_settings_with_ancestors_inherited_settings]
        }] },
        widgets: { work_item_type: :enabled_widget_definitions },
        archived: {
          namespace: :namespace_settings_with_ancestors_inherited_settings,
          project: { namespace: :namespace_settings_with_ancestors_inherited_settings }
        }
      }
    end

    def nested_preloads
      {
        widgets: widget_preloads,
        user_permissions: { update_work_item: :assignees },
        project: { jira_import_status: { project: :jira_imports } },
        author: {
          location: { author: :user_detail },
          gitpod_enabled: { author: :user_preference }
        }
      }
    end

    def widget_preloads
      {
        last_edited_by: :last_edited_by,
        assignees: :assignees_by_name_and_id,
        participants: WorkItem.participant_includes,
        parent: :work_item_parent,
        has_parent: :work_item_parent,
        children: { work_item_children_by_relative_position: [:author, { project: :project_feature }] },
        milestone: { milestone: [:project, :group] },
        subscribed: [:assignees, :award_emoji, { notes: [:author, :award_emoji] }],
        award_emoji: { award_emoji: :awardable },
        due_date: :dates_source,
        start_date: :dates_source,
        closing_merge_requests: { merge_requests_closing_issues: { merge_request: [:target_project, :author] } }
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
