# frozen_string_literal: true

module QA
  module Page
    module Group
      class BulkImport < Page::Base
        view "app/assets/javascripts/import_entities/import_groups/components/import_table.vue" do
          element 'import-item'
          element 'import-status-indicator'
          element 'filter-groups'
        end

        view "app/assets/javascripts/import_entities/components/import_target_dropdown.vue" do
          element 'target-namespace-dropdown'
        end

        view "app/assets/javascripts/import_entities/import_groups/components/import_actions_cell.vue" do
          element 'import-group-button'
        end

        def filter_group(source_group_name)
          find('input[data-testid="filter-groups"]').set(source_group_name).send_keys(:return)

          finished_loading?
        end

        # Import source group in to target group
        #
        # @param [String] source_group_name
        # @param [String] target_group_name
        # @return [void]
        def import_group(source_group_name, target_group_name)
          finished_loading?

          filter_group(source_group_name)

          within_element('import-item', source_group: source_group_name) do
            click_element('target-namespace-dropdown')
            click_element("listbox-item-#{target_group_name}")

            retry_until(message: "Triggering import") do
              click_element('import-group-button')
              # Make sure import started before waiting for completion
              has_no_element?('import-status-indicator', text: "Not started", wait: 1)
            end
          end
        end

        # Check if import page has a successfully imported group
        #
        # @param [String] source_group_name
        # @param [Integer] wait
        # @return [Boolean]
        def has_imported_group?(source_group_name, wait: QA::Support::WaitForRequests::DEFAULT_MAX_WAIT_TIME)
          within_element('import-item', source_group: source_group_name) do
            has_element?('import-status-indicator', text: "Complete", wait: wait)
          end
        end
      end
    end
  end
end
