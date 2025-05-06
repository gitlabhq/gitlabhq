# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Runners < Page::Base
          view 'app/helpers/ci/runners_helper.rb' do
            element 'runner-status-icon'
          end

          def has_online_runner?(runner_id)
            runner_element = find_element("#runner_#{runner_id}")
            within(runner_element) do
              has_element?('runner-status-icon', status: 'online')
            end
          end
        end
      end
    end
  end
end
