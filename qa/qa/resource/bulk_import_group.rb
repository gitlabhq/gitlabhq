# frozen_string_literal: true

module QA
  module Resource
    class BulkImportGroup < Group
      attributes :source_group_path,
                 :import_id

      attribute :destination_group_path do
        source_group_path
      end

      attribute :access_token do
        api_client.personal_access_token
      end

      alias_method :path, :source_group_path

      delegate :gitlab_address, to: 'QA::Runtime::Scenario'

      def fabricate_via_browser_ui!
        Page::Main::Menu.perform(&:go_to_create_group)

        Page::Group::New.perform do |group|
          group.switch_to_import_tab
          group.connect_gitlab_instance(gitlab_address, api_client.personal_access_token)
        end

        Page::Group::BulkImport.perform do |import_page|
          import_page.import_group(path, sandbox.path)
        end

        reload!
        visit!
      end

      def fabricate_via_api!
        resource_web_url(api_post)
      end

      def api_post_path
        '/bulk_imports'
      end

      def api_post_body
        {
          configuration: {
            url: gitlab_address,
            access_token: access_token
          },
          entities: [
            {
              source_type: 'group_entity',
              source_full_path: source_group_path,
              destination_name: destination_group_path,
              destination_namespace: sandbox.path
            }
          ]
        }
      end

      def import_status
        response = get(Runtime::API::Request.new(api_client, "/bulk_imports/#{import_id}").url)

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get import status. Request returned (#{response.code}): `#{response}`."
        end

        parse_body(response)[:status]
      end

      private

      def transform_api_resource(api_resource)
        return api_resource if api_resource[:web_url]

        # override transformation only for /bulk_imports endpoint which doesn't have web_url in response and
        # ignore others so import_id is not overwritten incorrectly
        api_resource[:web_url] = "#{gitlab_address}/#{full_path}"
        api_resource[:import_id] = api_resource[:id]
        api_resource
      end
    end
  end
end
