# frozen_string_literal: true

module QA
  module Resource
    class CiVariable < Base
      attr_accessor :key, :value, :masked, :protected, :variable_type

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-ci-variables'
          resource.description = 'project for adding CI variable test'
        end
      end

      def initialize
        @masked = false
        @protected = false
        @variable_type = 'env_var'
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
        "/projects/#{project.id}/variables/#{key}"
      end

      def api_post_path
        "/projects/#{project.id}/variables"
      end

      def api_post_body
        {
          key: key,
          value: value,
          masked: masked,
          protected: protected,
          variable_type: variable_type
        }
      end
    end
  end
end
