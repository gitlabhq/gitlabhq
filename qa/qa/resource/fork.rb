# frozen_string_literal: true

module QA
  module Resource
    class Fork < Base
      attribute :project do
        Resource::Project.fabricate! do |resource|
          resource.name = upstream.project.name
          resource.path_with_namespace = "#{user.name}/#{upstream.project.name}"
        end
      end

      attribute :upstream do
        Repository::ProjectPush.fabricate!
      end

      attribute :user do
        User.fabricate! do |resource|
          if Runtime::Env.forker?
            resource.username = Runtime::Env.forker_username
            resource.password = Runtime::Env.forker_password
          end
        end
      end

      def fabricate!
        populate(:upstream, :user)

        # Sign out as admin and sign is as the fork user
        Page::Main::Menu.perform(&:sign_out)
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform do |login|
          login.sign_in_using_credentials(user: user)
        end

        upstream.project.visit!

        Page::Project::Show.perform(&:fork_project)

        Page::Project::Fork::New.perform do |fork_new|
          fork_new.choose_namespace(user.name)
        end

        Page::Layout::Banner.perform do |banner|
          banner.has_notice?('The project was successfully forked.')
        end

        populate(:project)
      end
    end
  end
end
