# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Project < Base
      include Events::Project

      attr_writer :initialize_with_readme

      attribute :id
      attribute :name
      attribute :description

      attribute :group do
        Group.fabricate!
      end

      attribute :path_with_namespace do
        "#{group.sandbox.path}/#{group.path}/#{name}" if group
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
        @description = 'My awesome project'
        @initialize_with_readme = false
      end

      def name=(raw_name)
        @name = "#{raw_name}-#{SecureRandom.hex(8)}"
      end

      def fabricate!
        group.visit!

        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform do |page|
          page.choose_test_namespace
          page.choose_name(@name)
          page.add_description(@description)
          page.set_visibility('Public')
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

      def api_post_path
        '/projects'
      end

      def api_post_body
        {
          namespace_id: group.id,
          path: name,
          name: name,
          description: description,
          visibility: 'public',
          initialize_with_readme: @initialize_with_readme
        }
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
