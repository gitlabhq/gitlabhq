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

          Page::Project::Fork::New.perform do |fork_new|
            fork_new.choose_namespace(user.name)
          end

          Page::Layout::Banner.act { has_notice?('The project was successfully forked.') }
        end
      end
    end
  end
end
