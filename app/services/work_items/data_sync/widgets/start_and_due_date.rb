# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class StartAndDueDate < Base
        def after_create
          return unless target_work_item.get_widget(:start_and_due_date)

          dates_source = target_work_item.dates_source || target_work_item.build_dates_source

          dates_source.assign_attributes(build_date_source_attributes)
          target_work_item.dates_source = dates_source
        end

        # NOTE: This method is for cleanup simulation and testing purposes, it is not actually called within the
        # application yet.
        #
        # In the product, the post move cleanup of widget data is going to be implemented later.
        def post_move_cleanup
          # The update is only done here for testing purposes, these attributes will be removed upon original work item
          # cleanup.
          work_item.update(start_date: nil, due_date: nil)
          work_item.dates_source&.destroy
        end

        private

        def build_date_source_attributes
          if work_item.dates_source
            # If original item has a DatesSource record use that to build the DatesSource record for the
            # target work item as it will copy other data like is fixed date, etc
            # Because we have a trigger on the `work_item_dates_sources` table which would copy start and due dates to
            # the issues table, thus overwriting the start and due date on the issues table, we need to make sure that
            # we do not overwrite an existing value in issues table with NULL,
            # see WorkItem#start_date and WorkItem#due_date implementations for more details
            work_item.dates_source.attributes.except('namespace_id', 'issue_id').merge(
              "start_date" => work_item.start_date,
              "due_date" => work_item.due_date
            )
          else
            # otherwise build the DatesSource record from existing data
            target_work_item.start_date = work_item.read_attribute(:start_date)
            target_work_item.due_date = work_item.read_attribute(:due_date)
            target_work_item.date_source_attributes_from_current_dates
          end
        end
      end
    end
  end
end

WorkItems::DataSync::Widgets::StartAndDueDate.prepend_mod
