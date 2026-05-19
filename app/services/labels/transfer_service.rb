# frozen_string_literal: true

# Labels::TransferService class
#
# User for recreate the missing group labels at project level
#
module Labels
  # rubocop: disable CodeReuse/ActiveRecord
  class TransferService
    include Gitlab::Utils::StrongMemoize

    BATCH_SIZE = 500
    MAX_LABEL_IDS = 10_000

    # At this point, project has already been moved to the new namespace target
    def initialize(current_user, old_group, project)
      @current_user = current_user
      @old_group = old_group
      @project = project
    end

    def execute
      return unless old_group.present?

      # Cache label_ids outside of the transaction
      # (For project transfers this service is already called inside a transaction)
      group_label_ids

      Label.transaction do
        group_label_ids.each do |id_batch|
          group_labels_to_transfer(id_batch).find_each(batch_size: BATCH_SIZE) do |label|
            new_label_id = find_or_create_label!(label)

            next if new_label_id == label.id

            update_all_label_links(old_label_id: label.id, new_label_id: new_label_id)
            update_label_priorities(old_label_id: label.id, new_label_id: new_label_id)
          end
        end
      end
    end

    private

    attr_reader :current_user, :old_group, :project

    def group_label_ids
      label_ids = Set.new

      project_label_links.distinct_each_batch(column: :label_id, of: BATCH_SIZE) do |batch|
        label_ids.merge(batch.pluck(:label_id))
      end

      # We don't expect to ever have more than 10_000 label_ids here, just a precaution before
      # sending a big list in the query
      label_ids.each_slice(MAX_LABEL_IDS).map do |id_batch|
        Label.where(id: id_batch).where.not(group_id: nil).pluck(:id)
      end
    end
    strong_memoize_attr :group_label_ids

    def group_labels_to_transfer(label_ids)
      Label.where(id: label_ids)
    end

    def update_all_label_links(old_label_id:, new_label_id:)
      project_label_links.where(label_id: old_label_id).each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(label_id: new_label_id)
      end
    end

    def project_label_links
      LabelLink.where(namespace_id: project.project_namespace_id)
    end

    def find_or_create_label!(label)
      params    = label.attributes.slice('title', 'description', 'color')
      new_label = FindOrCreateService.new(
        current_user,
        project,
        params.merge(include_ancestor_groups: true)
      ).execute(skip_authorization: true)

      new_label.id
    end

    def update_label_priorities(old_label_id:, new_label_id:)
      LabelPriority.where(project_id: project.id, label_id: old_label_id)
        .update_all(label_id: new_label_id)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
