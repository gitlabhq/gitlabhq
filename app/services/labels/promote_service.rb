# frozen_string_literal: true

module Labels
  class PromoteService < BaseService
    BATCH_SIZE = 1000

    # rubocop: disable CodeReuse/ActiveRecord
    def execute(label)
      return unless project.group &&
        label.is_a?(ProjectLabel)

      ProjectLabel.transaction do
        # use the existing group label if it exists
        group_label = find_or_create_group_label(label)

        label_ids_for_merge(group_label).find_in_batches(batch_size: BATCH_SIZE) do |batched_ids|
          update_old_label_relations(group_label, batched_ids)
          destroy_project_labels(batched_ids)
        end

        group_label
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def update_old_label_relations(group_label, old_label_ids)
      update_issuables(group_label, old_label_ids)
      update_resource_label_events(group_label, old_label_ids)
      update_issue_board_lists(group_label, old_label_ids)
      update_priorities(group_label, old_label_ids)
      subscribe_users(group_label, old_label_ids)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def subscribe_users(group_label, label_ids)
      # users can be subscribed to multiple labels that will be merged into the group one
      # we want to keep only one subscription / user
      ids_to_update = Subscription.where(subscribable_id: label_ids, subscribable_type: 'Label')
        .group(:user_id)
        .pluck('MAX(id)')
      Subscription.where(id: ids_to_update).update_all(subscribable_id: group_label.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def label_ids_for_merge(group_label)
      LabelsFinder
        .new(current_user, title: group_label.title, group_id: project.group.id)
        .execute(skip_authorization: true)
        .where.not(id: group_label)
        .select(:id, :project_id, :group_id, :type) # Can't use pluck() to avoid object-creation because of the batching
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def update_issuables(group_label, label_ids)
      LabelLink
        .where(label: label_ids)
        .update_all(label_id: group_label.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def update_resource_label_events(group_label, label_ids)
      ResourceLabelEvent
        .where(label: label_ids)
        .update_all(label_id: group_label.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def update_issue_board_lists(group_label, label_ids)
      List
        .where(label: label_ids)
        .update_all(label_id: group_label.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def update_priorities(group_label, label_ids)
      LabelPriority
        .where(label: label_ids)
        .update_all(label_id: group_label.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_project_labels(label_ids)
      Label.where(id: label_ids).destroy_all # rubocop: disable Cop/DestroyAll
    end

    def find_or_create_group_label(label)
      params = label.attributes.slice('title', 'description', 'color')
      new_label = GroupLabel.create_with(params).find_or_initialize_by(group_id: project.group.id, title: label.title)

      new_label.save! unless new_label.persisted?
      new_label
    end
  end
end

Labels::PromoteService.prepend_mod_with('Labels::PromoteService')
