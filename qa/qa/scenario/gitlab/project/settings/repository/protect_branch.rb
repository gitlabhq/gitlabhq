module QA
  module Scenario
    module Gitlab
      module Project
        module Settings
          module Repository
            class ProtectBranch < Scenario::Template
              attr_writer :project_name,
                          :branch,
                          :action

              def perform
                Scenario::Gitlab::Sandbox::Prepare.perform
              end
            end
          end
        end
      end
    end
  end
end
