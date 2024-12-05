# frozen_string_literal: true

module QA
  module Resource
    class Fork < Project
      attribute :name do
        upstream.name
      end

      attribute :upstream do
        Resource::Project.fabricate_via_api! do |resource|
          resource.initialize_with_readme = true
        end
      end

      attribute :user do
        Runtime::User::Store.test_user
      end

      attribute :path_with_namespace do
        "#{namespace_path}/#{name}"
      end

      attribute :namespace_path do
        user.username
      end

      def fabricate!
        populate(:upstream, :user)
        set_personal_namespace

        # Sign out as admin and sign is as the fork user
        Flow::Login.sign_in(as: user)

        upstream.visit!

        Page::Project::Show.perform(&:fork_project)

        Page::Project::Fork::New.perform do |fork_new|
          fork_new.fork_project(namespace_path)
        end

        Page::Project::Show.perform do |project_page|
          raise ResourceFabricationFailedError, "Forking failed!" unless project_page.forked_from?(upstream.name)
        end

        populate(:project)
      end

      def fabricate_via_api!
        populate(:upstream, :user)
        set_personal_namespace

        Runtime::Logger.debug("Forking project #{name} to namespace #{namespace_path}...")
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        response = super

        Support::Retrier.retry_until(
          max_duration: import_wait_duration,
          sleep_interval: 5,
          retry_on_exception: true,
          message: "Wait for project to be forked"
        ) do
          reload!.api_resource[:import_status] == "finished"
        end

        response
      end

      # Api client
      #
      # Api client is set as public for MergeRequestFromFork resource to use correct client
      #
      # @return [Runtime::API::Client]
      def api_client
        @api_client ||= user.api_client
      end

      def api_get_path
        "/projects/#{CGI.escape(path_with_namespace)}"
      end

      def api_post_path
        "/projects/#{upstream.id}/fork"
      end

      def api_post_body
        {
          namespace_path: namespace_path,
          name: name,
          path: name
        }
      end

      def sandbox_path
        ""
      end

      def set_personal_namespace
        return unless namespace_path == user.username

        @personal_namespace = user.username
      end
    end
  end
end
