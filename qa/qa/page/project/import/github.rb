# frozen_string_literal: true

module QA
  module Page
    module Project
      module Import
        class Github < Page::Base
          view 'app/views/import/github/new.html.haml' do
            element 'personal-access-token-field'
            element 'authenticate-button'
          end

          view 'app/assets/javascripts/import_entities/import_projects/components/advanced_settings.vue' do
            element 'advanced-settings-checkbox'
          end

          view 'app/assets/javascripts/import_entities/import_projects/components/provider_repo_table_row.vue' do
            element 'project-import-row'
            element 'project-path-field'
            element 'import-button'
            element 'go-to-project-link'
            element 'import-status-indicator'
          end

          view "app/assets/javascripts/import_entities/components/import_target_dropdown.vue" do
            element 'target-namespace-dropdown'
          end

          # Add personal access token
          #
          # @param [String] personal_access_token
          # @return [void]
          def add_personal_access_token(personal_access_token)
            # If for some reasons this process is retried, user cannot re-enter github token in the same group
            # In this case skip this step and proceed to import project row
            return unless has_element?('personal-access-token-field')

            raise ArgumentError, "No personal access token was provided" if personal_access_token.empty?

            fill_element('personal-access-token-field', personal_access_token)
            click_element('authenticate-button')
            finished_loading?
          end

          # Import project
          #
          # @param [String] source_project_name
          # @param [String] target_group_path
          # @return [void]
          def import!(gh_project_name, target_group_path, project_name)
            within_element('project-import-row', source_project: gh_project_name) do
              click_element('target-namespace-dropdown')
              click_element("listbox-item-#{target_group_path}", wait: 10)
              fill_element('project-path-field', project_name)

              retry_until do
                click_element('import-button')
                # Make sure import started before waiting for completion
                has_no_element?('import-status-indicator', text: "Not started", wait: 1)
              end
            end
          end

          # Check Go to project button present
          #
          # @param [String] gh_project_name
          # @return [Boolean]
          def has_go_to_project_link?(gh_project_name)
            within_element('project-import-row', source_project: gh_project_name) do
              has_element?('go-to-project-link')
            end
          end

          # Check if import page has a successfully imported project
          #
          # @param [String] source_project_name
          # @param [Integer] wait
          # @return [Boolean]
          def has_imported_project?(
            gh_project_name,
            wait: QA::Support::WaitForRequests::DEFAULT_MAX_WAIT_TIME,
            allow_partial_import: false
          )
            within_element('project-import-row', source_project: gh_project_name, skip_finished_loading_check: true) do
              wait_until(
                max_duration: wait,
                sleep_interval: 5,
                reload: false,
                skip_finished_loading_check_on_refresh: true
              ) do
                status_selector = 'import-status-indicator'

                next has_element?(status_selector, text: "Complete", wait: 1) unless allow_partial_import

                ["Partially completed", "Complete"].any? do |status|
                  has_element?(status_selector, text: status, wait: 1)
                end
              end
            end
          end
          alias_method :wait_for_success, :has_imported_project?

          # Select advanced github import option
          #
          # @param [Symbol] option_name
          # @return [void]
          def select_advanced_option(option_name)
            check_element('advanced-settings-checkbox', true, option_name: option_name)
          end
        end
      end
    end
  end
end
