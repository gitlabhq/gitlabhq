# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class LinkedItems < Base
        def after_save_commit
          return unless params[:operation] == :move
          return unless target_work_item.get_widget(:linked_items)

          recreate_related_items
        end

        # NOTE: No need to override this in EE for legacy ::Epic::RelatedEpicLink records, because
        # ::Epic::RelatedEpicLink records are built to contain `issue_link_id` FK with ON DELETE CASCADE,
        # which would delete ::Epic::RelatedEpicLink when corresponding IssueLink records for a given Epic Work Item
        # are deleted in this method.
        def post_move_cleanup
          IssueLink.for_source(work_item).each_batch(of: BATCH_SIZE, column: :target_id) do |links_batch|
            links_batch.delete_all
          end

          IssueLink.for_target(work_item).each_batch(of: BATCH_SIZE, column: :source_id) do |links_batch|
            links_batch.delete_all
          end
        end

        private

        def recreate_related_items
          IssueLink.for_source(work_item).each_batch(of: BATCH_SIZE, column: :target_id) do |links_batch|
            new_links = new_issue_links(links_batch, reference_attribute: 'source_id')
            ::IssueLink.insert_all(new_links) if new_links.any?
          end

          IssueLink.for_target(work_item).each_batch(of: BATCH_SIZE, column: :source_id) do |links_batch|
            new_links = new_issue_links(links_batch, reference_attribute: 'target_id')
            ::IssueLink.insert_all(new_links) if new_links.any?
          end
        end

        def new_issue_links(links_batch, reference_attribute:)
          links_batch.map do |link|
            link.attributes.except('id', 'namespace_id').merge(reference_attribute => target_work_item.id)
          end
        end
      end
    end
  end
end

WorkItems::DataSync::Widgets::LinkedItems.prepend_mod
