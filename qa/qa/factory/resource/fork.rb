module QA
  module Factory
    module Resource
      class Fork < Factory::Base
        dependency Factory::Resource::Sandbox, as: :sandbox do |sandbox|
          sandbox.name = "Sandbox-#{SecureRandom.hex(8)}"
          sandbox.visibility = 'Public'
        end

        dependency Factory::Resource::Project, as: :project do |project, factory|
          project.group = factory.sandbox
          project.namespace = factory.sandbox.name
          project.name = 'project-to-fork'
          project.visibility = 'Public'
        end

        dependency Factory::Repository::ProjectPush, as: :push do |push, factory|
          push.project = factory.project
        end

        dependency Factory::Resource::User, as: :user

        product(:user) {|factory| factory.user}

        def fabricate!
          project.visit!
          Page::Project::Show.act { fork_project }
          Page::Project::Fork::New.perform do |page|
            page.choose_namespace(user.name)
            page.wait do
              page.has_content?('The project was successfully forked.')
            end
          end
        end
      end
    end
  end
end
