module QA
  module Scenario
    module Test
      module Integration
        class Github < Test::Instance::All
          tags :github

          def perform(address, *rspec_options)
            # This test suite requires a GitHub personal access token
            Runtime::Env.require_github_access_token!

            super
          end
        end
      end
    end
  end
end
