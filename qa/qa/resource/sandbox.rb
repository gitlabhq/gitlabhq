# frozen_string_literal: true

module QA
  module Resource
    ##
    # Ensure we're in our sandbox namespace, either by navigating to it or by
    # creating it if it doesn't yet exist.
    #
    class Sandbox < Base
      include Members

      attr_accessor :path

      attribute :id
      attribute :runners_token
      attribute :name
      attribute :full_path

      def initialize
        @path = Runtime::Namespace.sandbox_name
      end

      def fabricate!
        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform do |groups_page|
          if groups_page.has_group?(path)
            groups_page.click_group(path)
          else
            groups_page.click_new_group

            Page::Group::New.perform do |group|
              group.set_path(path)
              group.set_description('GitLab QA Sandbox Group')
              group.set_visibility('Public')
              group.create
            end
          end
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super

        # If the group was just created the runners token might not be
        # available via the API immediately.
        Support::Retrier.retry_on_exception(sleep_interval: 5) do
          resource = resource_web_url(api_get)
          populate(:runners_token)
          resource
        end
      end

      def api_get_path
        "/groups/#{path}"
      end

      def api_members_path
        "#{api_get_path}/members"
      end

      def api_post_path
        '/groups'
      end

      def api_delete_path
        "/groups/#{id}"
      end

      def api_post_body
        {
          path: path,
          name: path,
          visibility: 'public'
        }
      end

      def api_put_path
        "/groups/#{id}"
      end

      def update_group_setting(group_setting:, value:)
        put_body = { "#{group_setting}": value }
        response = put Runtime::API::Request.new(api_client, api_put_path).url, put_body

        unless response.code == HTTP_STATUS_OK
          raise ResourceUpdateFailedError, "Could not update #{group_setting} to #{value}. Request returned (#{response.code}): `#{response}`."
        end
      end
    end
  end
end
