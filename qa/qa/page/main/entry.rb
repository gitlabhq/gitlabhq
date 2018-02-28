module QA
  module Page
    module Main
      class Entry < Page::Base
        def visit_login_page
          visit("#{Runtime::Scenario.gitlab_address}/users/sign_in")
          wait_for_instance_to_be_ready
        end

        private

        def wait_for_instance_to_be_ready
          # This resolves cold boot / background tasks problems
          #
          start = Time.now

          while Time.now - start < 240
            break if page.has_css?('.application', wait: 10)

            refresh
          end
        end
      end
    end
  end
end
