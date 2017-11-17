module QA
  module Page
    module Main
      class Entry < Page::Base
        def visit_login_page
          wait(time: 500) do
            visit("#{Runtime::Scenario.gitlab_address}/users/sign_in")
          end
        end
      end
    end
  end
end
