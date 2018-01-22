module QA
  module Page
    module Project
      module Settings
        class Runners < Page::Base
          def registration_token
            find('code#registration_token').text
          end

          def coordinator_address
            # TODO, this needs a specific ID or QA class
            #
            all('code').first.text
          end

          def has_online_runner?
            page.has_css?('.runner-status-online')
          end
        end
      end
    end
  end
end
