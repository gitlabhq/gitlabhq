# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Runners < Page::Base
          view 'app/helpers/ci/runners_helper.rb' do
            element 'runner-status-icon'
          end

          def has_online_runner?
            has_element?('runner-status-icon', status: 'online')
          end

          def has_offline_runner?
            has_element?('runner-status-icon', status: 'offline')
          end
        end
      end
    end
  end
end
