# frozen_string_literal: true

module QA
  module Page
    module Project
      module Job
        class Show < QA::Page::Base
          include Component::CiIcon

          view 'app/assets/javascripts/ci/job_details/components/log/log.vue' do
            element 'job-log-content'
          end

          view 'app/assets/javascripts/ci/job_details/components/sidebar/stages_dropdown.vue' do
            element 'pipeline-path', required: true
          end

          view 'app/assets/javascripts/ci/job_details/components/sidebar/sidebar_header.vue' do
            element 'retry-button'
          end

          view 'app/assets/javascripts/ci/job_details/components/sidebar/artifacts_block.vue' do
            element 'browse-artifacts-button'
            element 'artifacts-unlocked-message-content'
            element 'artifacts-locked-message-content'
          end

          def successful?(timeout: 60)
            raise "Timed out waiting for the build trace to load" unless loaded?
            raise "Timed out waiting for the status to be a valid completed state" unless completed?(timeout: timeout)

            QA::Runtime::Logger.debug(" \n\n ------- Job log: ------- \n\n #{job_log} \n -------")

            passed?
          end

          # Reminder: You may wish to wait for a particular job status before checking output
          def output(wait: 5)
            result = ''

            wait_until(reload: false, max_duration: wait, sleep_interval: 1) do
              result = job_log.include?('Job') ? job_log : ''
              result.present?
            end

            result
          end

          def has_browse_button?
            has_element?('browse-artifacts-button')
          end

          def click_browse_button
            click_element('browse-artifacts-button')
          end

          def retry!
            click_element 'retry-button'
          end

          def has_job_log?(wait: 1)
            has_element?('job-log-content', wait: wait)
          end

          def has_status?(status, wait: 30)
            wait_until(reload: false, max_duration: wait, sleep_interval: 1) do
              status_badge == status
            end
          end

          def has_locked_artifact?(wait: 240)
            wait_until(reload: true, max_duration: wait, sleep_interval: 1) do
              has_element?('artifacts-locked-message-content')
            end
          end

          # Artifact unlock is async and depends on queue size on target env
          def has_unlocked_artifact?(wait: 240)
            wait_until(reload: true, max_duration: wait, sleep_interval: 1) do
              has_element?('artifacts-unlocked-message-content')
            end
          end

          def go_to_pipeline
            click_element('pipeline-path')
          end

          private

          def loaded?(wait: 60)
            wait_until(reload: true, max_duration: wait, sleep_interval: 1) do
              has_job_log?
            end
          end

          def job_log
            find_element('job-log-content').text
          end
        end
      end
    end
  end
end

QA::Page::Project::Job::Show.prepend_mod_with('Page::Project::Job::Show', namespace: QA)
