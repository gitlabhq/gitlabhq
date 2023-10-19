# frozen_string_literal: true

module QA
  module Page
    module Project
      module Artifacts
        class Index < QA::Page::Base
          view 'app/assets/javascripts/ci/artifacts/components/job_artifacts_table.vue' do
            element 'select-all-artifacts-checkbox'
          end

          view 'app/assets/javascripts/ci/artifacts/components/artifacts_bulk_delete.vue' do
            element 'bulk-delete-delete-button'
          end

          view 'app/assets/javascripts/ci/artifacts/components/bulk_delete_modal.vue' do
            element 'artifacts-bulk-delete-modal'
          end

          view 'app/assets/javascripts/ci/artifacts/components/job_artifacts_table.vue' do
            element 'job-artifacts-count'
            element 'job-artifacts-size'
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

          def job_artifacts_count_by_row(row: 1)
            all_elements('job-artifacts-count', minimum: row)[row - 1].text.gsub(/[^0-9]/, '').to_i
          end

          def job_artifacts_size_by_row(row: 1)
            all_elements('job-artifacts-size', minimum: row)[row - 1].text.gsub(/[^0-9]/, '').to_f
          end
        end
      end
    end
  end
end
