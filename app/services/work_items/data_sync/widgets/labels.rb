# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Labels < Base
        include Gitlab::Utils::StrongMemoize

        def after_save_commit
          return unless target_work_item.get_widget(:labels)
          return if work_item.labels.blank?

          work_item.label_links.with_label.each_batch(of: BATCH_SIZE) do |label_links_batch|
            new_label_links = new_work_item_label_links(label_links_batch)
            ::LabelLink.insert_all(new_label_links) unless new_label_links.blank?

            handle_changed_labels_system_notes(label_links_batch)
          end
        end

        # overwritten in EE
        def post_move_cleanup
          work_item.label_links.each_batch(of: BATCH_SIZE) do |label_links_batch|
            label_links_batch.by_targets([work_item]).delete_all
          end
        end

        private

        def new_work_item_label_links(label_links_batch)
          label_links_batch.filter_map do |label_link|
            next unless cloneable_labels[label_link.label.title].present?

            label_link.attributes.except("id").tap do |ep|
              ep["target_id"] = target_work_item.id
              # we want to explicitly set this because for legacy Epic we can have some labels linked to the
              # Epic Work Item(i.e. target_type=Issue) and some to the legacy Epic(i.e target_type=Epic)
              ep["target_type"] = target_work_item.class.base_class.name
              ep["label_id"] = cloneable_labels[label_link.label.title]
            end
          end
        end

        def handle_changed_labels_system_notes(label_links_batch)
          added_labels_ids = []
          removed_labels_ids = []

          label_links_batch.each do |label_link|
            if cloneable_labels[label_link.label.title]
              next if label_link.label_id == cloneable_labels[label_link.label.title]

              added_labels_ids << cloneable_labels[label_link.label.title]
            end

            removed_labels_ids << label_link.label_id
          end

          return if added_labels_ids.empty? && removed_labels_ids.empty?

          # reset resource event timestamp, otherwise the changed labels system notes appear as happening when
          # work item is created or even a couple milliseconds earlier.
          target_work_item.system_note_timestamp = Time.current
          ResourceEvents::ChangeLabelsService.new(target_work_item, current_user).execute(
            added_labels: Label.id_in(added_labels_ids),
            removed_labels: Label.id_in(removed_labels_ids)
          )
        end

        def cloneable_labels
          params = {
            project_id: target_work_item.project&.id,
            group_id: group&.id,
            title: work_item.labels.select(:title),
            include_ancestor_groups: true
          }

          params[:only_group_labels] = true if target_work_item.namespace.is_a?(Group)

          # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- limit is defined above
          # rubocop:disable CodeReuse/ActiveRecord -- we need just title and id
          LabelsFinder.new(current_user, params).execute.pluck(:title, :id).to_h
          # rubocop:enable Database/AvoidUsingPluckWithoutLimit
          # rubocop:enable CodeReuse/ActiveRecord
        end
        strong_memoize_attr :cloneable_labels

        def group
          if target_work_item.namespace.is_a?(Group)
            target_work_item.namespace
          elsif target_work_item.namespace&.parent && current_user.can?(:read_group, target_work_item.namespace&.parent)
            target_work_item.namespace&.parent
          end
        end
      end
    end
  end
end

WorkItems::DataSync::Widgets::Labels.prepend_mod
