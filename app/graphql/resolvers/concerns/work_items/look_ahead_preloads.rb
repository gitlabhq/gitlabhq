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
        web_url: { namespace: :route, project: [:project_namespace, { namespace: :route }] },
        widgets: { work_item_type: :enabled_widget_definitions },
        archived: :project
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
        assignees: :assignees,
        participants: WorkItem.participant_includes,
        parent: :work_item_parent,
        children: { work_item_children_by_relative_position: [:author, { project: :project_feature }] },
        labels: :labels,
        milestone: { milestone: [:project, :group] },
        subscribed: [:assignees, :award_emoji, { notes: [:author, :award_emoji] }],
        award_emoji: { award_emoji: :awardable }
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
