# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Runners < Page::Base
          view 'app/assets/javascripts/ci/runner/components/runner_status_badge.vue' do
            element 'runner-status-badge'
          end

          def has_online_runner?
            has_element?('runner-status-badge', status: 'ONLINE')
          end

          def has_offline_runner?
            has_element?('runner-status-badge', status: 'OFFLINE')
          end
        end
      end
    end
  end
end
