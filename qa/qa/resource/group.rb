# frozen_string_literal: true

module QA
  module Resource
    class Group < GroupBase
      attributes :require_two_factor_authentication, :description

      attribute :full_path do
        determine_full_path
      end

      attribute :sandbox do
        if Runtime::Env.personal_access_tokens_disabled?
          Resource::Sandbox.fabricate! do |sandbox|
            sandbox.path = Runtime::Namespace.sandbox_name
          end
        else
          Sandbox.fabricate_via_api! do |sandbox|
            sandbox.api_client = api_client
          end
        end
      end

      attribute :name do
        path
      end

      def initialize
        @description = "QA test run at #{Runtime::Namespace.time}"
        @path = Runtime::Namespace.group_name
        @require_two_factor_authentication = false
        # Add visibility to enable create private group
        @visibility = 'public'
      end

      def fabricate!
        sandbox.visit!

        Page::Group::Show.perform do |group_show|
          unless group_show.has_subgroup?(path)
            group_show.go_to_new_subgroup

            Page::Group::New.perform do |group_new|
              group_new.set_path(path)
              group_new.set_visibility(@visibility)
              group_new.create_subgroup
            end

            # Ensure that the group was actually created
            group_show.wait_until(sleep_interval: 1) do
              group_show.has_text?(path) &&
                group_show.has_new_project_and_new_subgroup_buttons?
            end
            sandbox.visit!
          end

          unless group_show.has_subgroup?(path)
            raise ResourceFabricationFailedError, "Resource at #{path} could not be found under #{sandbox.path}"
          end

          group_show.click_subgroup(path)
          @id = group_show.group_id
        end
      end

      # Fabricate a Group using the UI from the Groups Dashboard page
      # @param [String] group_name
      # @return [Page::Group::New]
      def fabricate_group!(group_name: nil)
        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |groups|
          groups.click_new_group

          Page::Group::New.perform do |group_new|
            group_new.click_create_group

            group_new.set_path(group_name)

            group_new.create
          end
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def api_get_path
        "/groups/#{CGI.escape(determine_full_path)}"
      end

      # Parameters included in the query URL
      #
      # @return [Hash]
      def query_parameters
        super.merge({ with_projects: false })
      end

      def api_post_body
        {
          parent_id: sandbox.id,
          path: path,
          name: name,
          visibility: @visibility.downcase,
          require_two_factor_authentication: @require_two_factor_authentication,
          avatar: avatar
        }
      end

      def set_require_two_factor_authentication(value:)
        put_body = { require_two_factor_authentication: value }
        response = put Runtime::API::Request.new(api_client, api_put_path).url, put_body
        return if response.code == HTTP_STATUS_OK

        raise(ResourceUpdateFailedError, <<~ERROR.strip)
          Could not update require_two_factor_authentication to #{value}. Request returned (#{response.code}): `#{response}`.
        ERROR
      end

      def change_repository_storage(new_storage)
        post_body = { destination_storage_name: new_storage }
        response = post Runtime::API::Request.new(api_client, "/groups/#{id}/repository_storage_moves").url, post_body

        unless response.code.between?(200, 300)
          raise(
            ResourceUpdateFailedError,
            "Could not change repository storage to #{new_storage}. Request returned (#{response.code}): `#{response}`."
          )
        end

        wait_until(sleep_interval: 1) do
          Runtime::API::RepositoryStorageMoves.has_status?(self, 'finished', new_storage)
        end
      rescue Support::Repeater::RepeaterConditionExceededError
        raise(
          Runtime::API::RepositoryStorageMoves::RepositoryStorageMovesError,
          'Timed out while waiting for the group repository storage move to finish'
        )
      end

      private

      # Determine the path up to the root group.
      #
      # This is equivalent to the full_path API attribute. We can't use the full_path attribute
      # because it depends on the group being fabricated first, and we use this method to help
      # _check_ if the group exists.
      #
      # @param [QA::Resource::GroupBase] sandbox the immediate parent group of this group
      # @param [String] path the path name of this group (the leaf, not the full path)
      # @return [String]
      def determine_full_path
        determine_parent_group_paths(sandbox, path)
      end

      # Recursively traverse the parents of this group up to the root group.
      #
      # @param [QA::Resource::GroupBase] parent the immediate parent group
      # @param [String] path the path traversed so far
      # @return [String]
      def determine_parent_group_paths(parent, path)
        return "#{parent.path}/#{path}" unless parent.respond_to?(:sandbox)

        determine_parent_group_paths(parent.sandbox, "#{parent.path}/#{path}")
      end
    end
  end
end
