module QA
  module Scenario
    module Gitlab
      module Project
        module Repository
          module Branch
            class Create < Scenario::Template
              attr_writer :ref,
                          :name

              def perform
                Scenario::Gitlab::Sandbox::Prepare.perform

                Scenario::Gitlab::Project::Create.perform do |project|
                  project.name = 'awesome-project'
                end

                Page::Project::Menu.act { branches }
                Page::Project::Repository::Branches.act { new }

                Page::Project::Repository::Branch::New.perform do |page|
                  page.choose_ref(@ref)
                  page.choose_name(@name)
                  page.create_branch
                end
              end
            end
          end
        end
      end
    end
  end
end
