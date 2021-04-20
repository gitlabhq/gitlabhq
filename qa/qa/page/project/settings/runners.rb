# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class Runners < Page::Base
          view 'app/views/ci/runner/_how_to_setup_runner.html.haml' do
            element :registration_token, '%code#registration_token' # rubocop:disable QA/ElementWithPattern
            element :coordinator_address, '%code#coordinator_address' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/helpers/ci/runners_helper.rb' do
            # rubocop:disable Lint/InterpolationCheck
            element :runner_status_icon, 'qa_selector: "runner_status_#{status}_content"' # rubocop:disable QA/ElementWithPattern
            # rubocop:enable Lint/InterpolationCheck
          end

          def registration_token
            find('code#registration_token').text
          end

          def coordinator_address
            find('code#coordinator_address').text
          end

          def has_online_runner?
            has_element?(:runner_status_online_content)
          end
        end
      end
    end
  end
end
