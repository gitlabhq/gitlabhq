# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Project < Base
      include Events::Project
      include Members

      attr_writer :initialize_with_readme
      attr_writer :auto_devops_enabled
      attr_writer :visibility

      attribute :id
      attribute :name
      attribute :add_name_uuid
      attribute :description
      attribute :standalone
      attribute :runners_token

      attribute :group do
        Group.fabricate!
      end

      attribute :path_with_namespace do
        "#{sandbox_path}#{group.path}/#{name}" if group
      end

      def sandbox_path
        group.respond_to?('sandbox') ? "#{group.sandbox.path}/" : ''
      end

      attribute :repository_ssh_location do
        Page::Project::Show.perform do |show|
          show.repository_clone_ssh_location
        end
      end

      attribute :repository_http_location do
        Page::Project::Show.perform do |show|
          show.repository_clone_http_location
        end
      end

      def initialize
        @add_name_uuid = true
        @standalone = false
        @description = 'My awesome project'
        @initialize_with_readme = false
        @auto_devops_enabled = true
        @visibility = 'public'
      end

      def name=(raw_name)
        @name = @add_name_uuid ? "#{raw_name}-#{SecureRandom.hex(8)}" : raw_name
      end

      def fabricate!
        unless @standalone
          group.visit!
          Page::Group::Show.perform(&:go_to_new_project)
        end

        Page::Project::New.perform do |new_page|
          new_page.choose_test_namespace
          new_page.choose_name(@name)
          new_page.add_description(@description)
          new_page.set_visibility(@visibility)
          new_page.enable_initialize_with_readme if @initialize_with_readme
          new_page.create_new_project
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def api_get_path
        "/projects/#{CGI.escape(path_with_namespace)}"
      end

      def api_get_archive_path(type = 'tar.gz')
        "#{api_get_path}/repository/archive.#{type}"
      end

      def api_members_path
        "#{api_get_path}/members"
      end

      def api_runners_path
        "#{api_get_path}/runners"
      end

      def api_post_path
        '/projects'
      end

      def api_post_body
        post_body = {
          name: name,
          description: description,
          visibility: @visibility,
          initialize_with_readme: @initialize_with_readme,
          auto_devops_enabled: @auto_devops_enabled
        }

        unless @standalone
          post_body[:namespace_id] = group.id
          post_body[:path] = name
        end

        post_body
      end

      def runners(tag_list: nil)
        response = get Runtime::API::Request.new(api_client, "#{api_runners_path}?tag_list=#{tag_list.compact.join(',')}").url
        parse_body(response)
      end

      def share_with_group(invitee, access_level = Resource::Members::AccessLevel::DEVELOPER)
        post Runtime::API::Request.new(api_client, "/projects/#{id}/share").url, { group_id: invitee.id, group_access: access_level }
      end

      private

      def transform_api_resource(api_resource)
        api_resource[:repository_ssh_location] =
          Git::Location.new(api_resource[:ssh_url_to_repo])
        api_resource[:repository_http_location] =
          Git::Location.new(api_resource[:http_url_to_repo])
        api_resource
      end
    end
  end
end
