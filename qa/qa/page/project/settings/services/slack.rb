# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        module Services
          class Slack < Chemlab::Page
            strong :slack_text, visible_text: /install/i

            def start_slack_install
              slack_link.click
            end

            def slack_link
              slack_text_element.parent
            end
          end
        end
      end
    end
  end
end
