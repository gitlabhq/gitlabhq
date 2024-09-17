# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module ResourceAccessToken
      extend self

      def build(resource_access_token, event, resource)
        base_data = {
          object_kind: 'access_token'
        }

        base_data[resource.model_name.param_key.to_sym] = resource.hook_attrs
        base_data[:object_attributes] = resource_access_token.hook_attrs
        base_data[:event_name] = event_data(event)
        base_data
      end

      private

      def event_data(event)
        case event
        when :expiring
          'expiring_access_token'
        end
      end
    end
  end
end
