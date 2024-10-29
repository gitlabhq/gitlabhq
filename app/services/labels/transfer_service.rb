# frozen_string_literal: true

# Labels::TransferService class
#
# User for recreate the missing group labels at project level
#
module Labels
  class TransferService
    def initialize(current_user, old_group, project)
      @current_user = current_user
      @old_group = old_group
      @project = project
    end

    def execute
      return unless old_group.present?

      # rubocop: disable CodeReuse/ActiveRecord
      link_ids = group_labels_applied_to_issues.pluck("label_links.id") +
        group_labels_applied_to_merge_requests.pluck("label_links.id")

      Label.transaction do
        labels_to_transfer.find_each do |label|
          new_label_id = find_or_create_label!(label)

          next if new_label_id == label.id

          update_label_links(link_ids, old_label_id: label.id, new_label_id: new_label_id)
          update_label_priorities(old_label_id: label.id, new_label_id: new_label_id)
        end
      end
    end

    private

    attr_reader :current_user, :old_group, :project

    def labels_to_transfer
      Label
        .from_union([
          group_labels_applied_to_issues,
          group_labels_applied_to_merge_requests
        ])
        .reorder(nil)
        .distinct
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def group_labels_applied_to_issues
      @labels_applied_to_issues ||= Label.joins(:issues)
        .joins("INNER JOIN namespaces on namespaces.id = labels.group_id AND namespaces.type = 'Group'")
        .where(issues: { project_id: project.id }).reorder(nil)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def group_labels_applied_to_merge_requests
      @labels_applied_to_mrs ||= Label.joins(:merge_requests)
        .joins("INNER JOIN namespaces on namespaces.id = labels.group_id AND namespaces.type = 'Group'")
        .where(merge_requests: { target_project_id: project.id }).reorder(nil)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_or_create_label!(label)
      params    = label.attributes.slice('title', 'description', 'color')
      new_label = FindOrCreateService.new(current_user, project, params.merge(include_ancestor_groups: true)).execute

      new_label.id
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def update_label_links(link_ids, old_label_id:, new_label_id:)
      LabelLink.where(id: link_ids, label_id: old_label_id)
        .update_all(label_id: new_label_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def update_label_priorities(old_label_id:, new_label_id:)
      LabelPriority.where(project_id: project.id, label_id: old_label_id)
        .update_all(label_id: new_label_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
