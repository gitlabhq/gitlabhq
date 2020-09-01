# frozen_string_literal: true

module QA
  module Resource
    class Fork < Base
      attribute :name do
        upstream.name
      end

      attribute :project do
        Resource::Project.fabricate_via_api! do |resource|
          resource.add_name_uuid = false
          resource.name = name
          resource.path_with_namespace = "#{user.username}/#{name}"
        end
      end

      attribute :upstream do
        Repository::ProjectPush.fabricate!.project
      end

      attribute :user do
        User.fabricate_via_api! do |resource|
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

        upstream.visit!

        Page::Project::Show.perform(&:fork_project)

        Page::Project::Fork::New.perform do |fork_new|
          fork_new.choose_namespace(user.name)
        end

        Page::Layout::Banner.perform do |banner|
          banner.has_notice?('The project was successfully forked.')
        end

        populate(:project)
      end

      def fabricate_via_api!
        populate(:upstream, :user)

        @api_client = Runtime::API::Client.new(:gitlab, is_new_session: false, user: user)

        Runtime::Logger.debug("Forking project #{upstream.name} to namespace #{user.username}...")
        super
        wait_until_forked

        populate(:project)
      end

      def api_get_path
        "/projects/#{CGI.escape(path_with_namespace)}"
      end

      def api_post_path
        "/projects/#{upstream.id}/fork"
      end

      def api_post_body
        {
          namespace_path: user.username,
          name: name,
          path: name
        }
      end

      def wait_until_forked
        Runtime::Logger.debug("Waiting for the fork process to complete...")
        forked = wait_until do
          project.import_status == "finished"
        end

        raise "Timed out while waiting for the fork process to complete." unless forked
      end
    end
  end
end
