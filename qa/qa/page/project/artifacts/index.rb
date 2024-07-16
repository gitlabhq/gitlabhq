# frozen_string_literal: true

module QA
  module Page
    module Project
      module Artifacts
        class Index < QA::Page::Base
          view 'app/assets/javascripts/ci/artifacts/components/job_artifacts_table.vue' do
            element 'select-all-artifacts-checkbox'
            element 'job-artifact-table-row'
          end

          view 'app/assets/javascripts/ci/artifacts/components/artifacts_bulk_delete.vue' do
            element 'bulk-delete-delete-button'
          end

          view 'app/assets/javascripts/ci/artifacts/components/bulk_delete_modal.vue' do
            element 'artifacts-bulk-delete-modal'
          end

          def select_all
            check_element('select-all-artifacts-checkbox', true)
          end

          def delete_selected_artifacts
            click_element('bulk-delete-delete-button')

            within_element('artifacts-bulk-delete-modal') do
              find_element('.js-modal-action-primary').click
            end
          end

          def has_no_artifacts?
            has_no_element?('job-artifact-table-row')
          end
        end
      end
    end
  end
end
