# frozen_string_literal: true

module QA
  module Resource
    class BulkImportGroup < Group
      attributes :source_group, :destination_group, :import_id

      attribute :import_access_token do
        api_client.personal_access_token
      end

      attribute :source_gitlab_address do
        QA::Runtime::Scenario.gitlab_address
      end

      # In most cases we will want to set path the same as source group
      # but it can be set to a custom name as well when imported via API
      attribute :destination_group_path do
        source_group.path
      end
      # Can't define path as attribue since @path is set in base class initializer
      alias_method :path, :destination_group_path

      def fabricate!
        Page::Main::Menu.perform(&:go_to_create_group)

        Page::Group::New.perform do |group|
          group.switch_to_import_tab
          group.connect_gitlab_instance(source_gitlab_address, import_access_token)
        end

        Page::Group::BulkImport.perform do |import_page|
          import_page.import_group(destination_group_path, sandbox.full_path)
          import_page.has_imported_group?(destination_group_path)
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
            url: source_gitlab_address,
            access_token: import_access_token
          },
          entities: [
            {
              source_type: 'group_entity',
              source_full_path: source_group.full_path,
              destination_name: destination_group_path,
              destination_namespace: sandbox.full_path
            }
          ]
        }
      end

      # Get import status
      #
      # @return [String]
      def import_status
        response = get(Runtime::API::Request.new(api_client, "/bulk_imports/#{import_id}").url)

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get import status. Request returned (#{response.code}): `#{response}`."
        end

        parse_body(response)[:status]
      end

      # Get import details
      #
      # @return [Array]
      def import_details
        response = get(Runtime::API::Request.new(api_client, "/bulk_imports/#{import_id}/entities").url)

        parse_body(response)
      end

      private

      def transform_api_resource(api_resource)
        return api_resource if api_resource[:web_url]

        # override transformation only for /bulk_imports endpoint which doesn't have web_url in response and
        # ignore others so import_id is not overwritten incorrectly
        api_resource[:web_url] = "#{QA::Runtime::Scenario.gitlab_address}/#{full_path}"
        api_resource[:import_id] = api_resource[:id]
        api_resource
      end
    end
  end
end
