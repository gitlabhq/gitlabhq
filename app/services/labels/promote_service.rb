module Labels
  class PromoteService < BaseService
    BATCH_SIZE = 1000

    def execute(label)
      return unless project.group &&
          label.is_a?(ProjectLabel)

      Label.transaction do
        new_label = clone_label_to_group_label(label)

        label_ids_for_merge(new_label).find_in_batches(batch_size: BATCH_SIZE) do |batched_ids|
          update_issuables(new_label, batched_ids)
          update_issue_board_lists(new_label, batched_ids)
          update_priorities(new_label, batched_ids)
          subscribe_users(new_label, batched_ids)
          # Order is important, project labels need to be last
          update_project_labels(batched_ids)
        end

        # We skipped validations during creation. Let's run them now, after deleting conflicting labels
        raise ActiveRecord::RecordInvalid.new(new_label) unless new_label.valid?

        new_label
      end
    end

    private

    def subscribe_users(new_label, label_ids)
      # users can be subscribed to multiple labels that will be merged into the group one
      # we want to keep only one subscription / user
      ids_to_update = Subscription.where(subscribable_id: label_ids, subscribable_type: 'Label')
        .group(:user_id)
        .pluck('MAX(id)')
      Subscription.where(id: ids_to_update).update_all(subscribable_id: new_label.id)
    end

    def label_ids_for_merge(new_label)
      LabelsFinder
        .new(current_user, title: new_label.title, group_id: project.group.id)
        .execute(skip_authorization: true)
        .where.not(id: new_label)
        .select(:id)  # Can't use pluck() to avoid object-creation because of the batching
    end

    def update_issuables(new_label, label_ids)
      LabelLink
        .where(label: label_ids)
        .update_all(label_id: new_label)
    end

    def update_issue_board_lists(new_label, label_ids)
      List
        .where(label: label_ids)
        .update_all(label_id: new_label)
    end

    def update_priorities(new_label, label_ids)
      LabelPriority
        .where(label: label_ids)
        .update_all(label_id: new_label)
    end

    def update_project_labels(label_ids)
      Label.where(id: label_ids).destroy_all
    end

    def clone_label_to_group_label(label)
      params = label.attributes.slice('title', 'description', 'color')
      # Since the title of the new label has to be the same as the previous labels
      # and we're merging old labels in batches we'll skip validation to omit 2-step
      # merge process and do it in one batch
      # We'll be forcing validation at the end of the transaction to ensure everything
      # was merged correctly
      new_label = GroupLabel.new(params.merge(group: project.group))
      new_label.save(validate: false)

      new_label
    end
  end
end
