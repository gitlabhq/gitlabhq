module QA
  module Scenario
    module Test
      module Administration
        class Backup
          def self.perform(address, *files)
            Test::Instance.perform(address, *files)

            QA::Service::Omnibus.new(options.name).act do
              gitlab_rake 'gitlab:backup:create'
            end
          end
        end
      end
    end
  end
end
