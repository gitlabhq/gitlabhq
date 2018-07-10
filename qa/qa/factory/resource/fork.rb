module QA
  module Factory
    module Resource
      class Fork < Factory::Base
        dependency Factory::Repository::ProjectPush, as: :push

        dependency Factory::Resource::User, as: :user

        product(:user) { |factory| factory.user }

        def fabricate!
          push.project.visit!
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
