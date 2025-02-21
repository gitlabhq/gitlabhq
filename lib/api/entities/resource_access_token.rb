# frozen_string_literal: true

module API
  module Entities
    class ResourceAccessToken < Entities::PersonalAccessToken
      expose :access_level,
        documentation: {
          type: 'integer',
          example: 40,
          description: 'Access level. Valid values are 10 (Guest), 20 (Reporter), 30 (Developer) \
      , 40 (Maintainer), and 50 (Owner). Defaults to 40.',
          values: [10, 20, 30, 40, 50]
        } do |token, _options|
        token.user.members.first.access_level
      end

      expose :resource_type,
        documentation: {
          type: 'string',
          example: 'project',
          description: 'Whether a token belongs to a project or group',
          values: %w[project group]
        } do |token, _options|
        token.user.bot_namespace && token.user.bot_namespace.is_a?(::Namespaces::ProjectNamespace) ? 'project' : 'group'
      end

      expose :resource_id,
        documentation: {
          type: 'integer',
          example: 1234,
          description: 'The ID of the project or group'
        } do |token, _options|
        bot_namespace = token.user.bot_namespace
        next unless bot_namespace

        bot_namespace.is_a?(::Namespaces::ProjectNamespace) ? bot_namespace.project.id : bot_namespace.id
      end
    end
  end
end
