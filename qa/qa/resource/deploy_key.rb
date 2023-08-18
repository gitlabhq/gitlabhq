# frozen_string_literal: true

module QA
  module Resource
    class DeployKey < Base
      attr_accessor :title, :key

      attribute :id

      attribute :sha256_fingerprint do
        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_deploy_keys do |key|
            key.find_sha256_fingerprint(title)
          end
        end
      end

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-deploy'
          resource.description = 'project for adding deploy key test'
        end
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_deploy_keys do |page|
            page.add_new_key
            page.fill_key_title(title)
            page.fill_key_value(key)

            page.add_key
          end
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/projects/#{project.id}/deploy_keys/#{find_id}"
      end

      def api_post_path
        "/projects/#{project.id}/deploy_keys"
      end

      def api_post_body
        {
          key: key,
          title: title
        }
      end

      private

      def find_id
        id
      rescue NoValueError
        found_key = auto_paginated_response(request_url("/projects/#{project.id}/deploy_keys", per_page: '100'))
          .find { |keys| keys[:key].strip == @key.strip }

        return found_key.fetch(:id) if found_key

        raise ResourceNotFoundError
      end
    end
  end
end
