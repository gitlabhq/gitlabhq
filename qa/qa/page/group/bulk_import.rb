# frozen_string_literal: true

module QA
  module Page
    module Group
      class BulkImport < Page::Base
        view "app/assets/javascripts/import_entities/import_groups/components/import_table.vue" do
          element :import_table
          element :import_item
          element :import_status_indicator
        end

        view "app/assets/javascripts/import_entities/import_groups/components/import_target_cell.vue" do
          element :target_group_dropdown_item
        end

        view "app/assets/javascripts/import_entities/components/group_dropdown.vue" do
          element :target_namespace_selector_dropdown
        end

        view "app/assets/javascripts/import_entities/import_groups/components/import_actions_cell.vue" do
          element :import_group_button
        end

        # Import source group in to target group
        #
        # @param [String] source_group_name
        # @param [String] target_group_name
        # @return [void]
        def import_group(source_group_name, target_group_name)
          finished_loading?

          within_element(:import_item, source_group: source_group_name) do
            click_element(:target_namespace_selector_dropdown)
            click_element(:target_group_dropdown_item, group_name: target_group_name)

            retry_until(message: "Triggering import") do
              click_element(:import_group_button)
              # Make sure import started before waiting for completion
              has_no_element?(:import_status_indicator, text: "Not started", wait: 1)
            end
          end
        end

        # Check if import page has a successfully imported group
        #
        # @param [String] source_group_name
        # @param [Integer] wait
        # @return [Boolean]
        def has_imported_group?(source_group_name, wait: QA::Support::WaitForRequests::DEFAULT_MAX_WAIT_TIME)
          within_element(:import_item, source_group: source_group_name) do
            has_element?(:import_status_indicator, text: "Complete", wait: wait)
          end
        end
      end
    end
  end
end
