# frozen_string_literal: true

module QA
  module Resource
    class Group < GroupBase
      attr_accessor :description

      attribute :sandbox do
        Sandbox.fabricate_via_api! do |sandbox|
          sandbox.api_client = api_client
        end
      end

      attribute :require_two_factor_authentication

      def initialize
        @path = Runtime::Namespace.name
        @description = "QA test run at #{Runtime::Namespace.time}"
        @require_two_factor_authentication = false
      end

      def fabricate!
        sandbox.visit!

        Page::Group::Show.perform do |group_show|
          if group_show.has_subgroup?(path)
            group_show.click_subgroup(path)
          else
            group_show.go_to_new_subgroup

            Page::Group::New.perform do |group_new|
              group_new.set_path(path)
              group_new.set_visibility('Public')
              group_new.create
            end

            # Ensure that the group was actually created
            group_show.wait_until(sleep_interval: 1) do
              group_show.has_text?(path) &&
                group_show.has_new_project_and_new_subgroup_buttons?
            end
          end
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def api_get_path
        "/groups/#{CGI.escape("#{sandbox.path}/#{path}")}"
      end

      def api_post_body
        {
          parent_id: sandbox.id,
          path: path,
          name: path,
          visibility: 'public',
          require_two_factor_authentication: @require_two_factor_authentication
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
    end
  end
end
