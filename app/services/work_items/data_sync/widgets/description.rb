# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Description < Base
        def before_create
          return unless target_work_item.get_widget(:description)

          # The service returns `description`, `description_html` and also `skip_markdown_cache_validation`.
          # We need to assign all of those attributes to the target work item.
          description_params = MarkdownContentRewriterService.new(
            current_user,
            work_item,
            :description,
            work_item.namespace,
            target_work_item.namespace
          ).execute

          target_work_item.assign_attributes(
            description_params.merge(
              last_edited_at: work_item.last_edited_at,
              last_edited_by: work_item.last_edited_by
            )
          )
        end

        def post_move_cleanup
          # Description is a field in the work_item record, it will be removed upon the work_item deletion
        end
      end
    end
  end
end
