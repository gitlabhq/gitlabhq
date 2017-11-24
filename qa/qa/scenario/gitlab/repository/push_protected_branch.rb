module QA
  module Scenario
    module Gitlab
      module Repository
        class PushProtectedBranche < Scenario::Template
          def perform
            # why do we have to do this? Could it be declarative
            # at the scenario level (overidable?)
            Scenario::Gitlab::Sandbox::Prepare.perform

            Page::Project::Settings::Repository.perform do |page|
              puts page.foo
            end
          end
        end
      end
    end
  end
end
