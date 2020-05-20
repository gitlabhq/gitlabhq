# frozen_string_literal: true

module QA
  module Page
    module Project
      module Job
        class Show < QA::Page::Base
          include Component::CiBadgeLink

          view 'app/assets/javascripts/jobs/components/log/log.vue' do
            element :job_log_content
          end

          view 'app/assets/javascripts/jobs/components/stages_dropdown.vue' do
            element :pipeline_path
          end

          view 'app/assets/javascripts/jobs/components/sidebar.vue' do
            element :retry_button
          end

          def successful?(timeout: 60)
            raise "Timed out waiting for the build trace to load" unless loaded?
            raise "Timed out waiting for the status to be a valid completed state" unless completed?(timeout: timeout)

            passed?
          end

          # Reminder: You may wish to wait for a particular job status before checking output
          def output(wait: 5)
            result = ''

            wait_until(reload: false, max_duration: wait, sleep_interval: 1) do
              result = find_element(:job_log_content).text

              result.include?('Job')
            end

            result
          end

          def retry!
            click_element :retry_button
          end

          private

          def loaded?(wait: 60)
            wait_until(reload: true, max_duration: wait, sleep_interval: 1) do
              has_element?(:job_log_content, wait: 1)
            end
          end
        end
      end
    end
  end
end
