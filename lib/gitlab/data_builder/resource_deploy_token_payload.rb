# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module ResourceDeployTokenPayload
      extend self

      def build(resource_deploy_token, event, resource, data = {})
        base_data = {
          object_kind: 'deploy_token'
        }

        base_data[resource.model_name.param_key.to_sym] = resource.hook_attrs
        base_data[:object_attributes] = resource_deploy_token.hook_attrs
        base_data[:event_name] = event_data(event)
        base_data.merge(data)
      end

      private

      def event_data(event)
        case event
        when :expiring
          'expiring_deploy_token'
        end
      end
    end
  end
end
