# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Project < Base
      include Events::Project

      attr_writer :initialize_with_readme
      attr_writer :visibility

      attribute :id
      attribute :name
      attribute :add_name_uuid
      attribute :description
      attribute :standalone

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
        Page::Project::Show.perform do |page|
          page.repository_clone_ssh_location
        end
      end

      attribute :repository_http_location do
        Page::Project::Show.perform do |page|
          page.repository_clone_http_location
        end
      end

      def initialize
        @add_name_uuid = true
        @standalone = false
        @description = 'My awesome project'
        @initialize_with_readme = false
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

        Page::Project::New.perform do |page|
          page.choose_test_namespace
          page.choose_name(@name)
          page.add_description(@description)
          page.set_visibility(@visibility)
          page.enable_initialize_with_readme if @initialize_with_readme
          page.create_new_project
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

      def api_post_path
        '/projects'
      end

      def api_post_body
        post_body = {
          name: name,
          description: description,
          visibility: @visibility,
          initialize_with_readme: @initialize_with_readme
        }

        unless @standalone
          post_body[:namespace_id] = group.id
          post_body[:path] = name
        end

        post_body
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
