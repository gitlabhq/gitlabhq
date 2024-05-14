# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module ResourceAccessToken
      extend self

      def build(resource_access_token, event, resource)
        base_data = {
          object_kind: 'access_token'
        }

        if resource.is_a?(Project)
          base_data[:project] = resource.hook_attrs
        else
          base_data[:group] = group_data(resource)
        end

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

      def group_data(group)
        {
          group_name: group.name,
          group_path: group.path,
          group_id: group.id
        }
      end
    end
  end
end
