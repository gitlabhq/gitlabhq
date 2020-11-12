# frozen_string_literal: true

module QA
  module Resource
    class Group < Base
      include Members

      attr_accessor :path, :description

      attribute :sandbox do
        Sandbox.fabricate_via_api! do |sandbox|
          sandbox.api_client = api_client
        end
      end

      attribute :full_path
      attribute :id
      attribute :name
      attribute :runners_token
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
              group_new.set_description(description)
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

      def api_put_path
        "/groups/#{id}"
      end

      def api_post_path
        '/groups'
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

      def api_delete_path
        "/groups/#{id}"
      end

      def set_require_two_factor_authentication(value:)
        put_body = { require_two_factor_authentication: value }
        response = put Runtime::API::Request.new(api_client, api_put_path).url, put_body

        unless response.code == HTTP_STATUS_OK
          raise ResourceUpdateFailedError, "Could not update require_two_factor_authentication to #{value}. Request returned (#{response.code}): `#{response}`."
        end
      end
    end
  end
end
