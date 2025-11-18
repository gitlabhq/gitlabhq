# frozen_string_literal: true

module Resolvers
  module WebHooks
    class ProjectHooksResolver < BaseResolver
      include ::LooksAhead
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :read_web_hook

      type Types::WebHooks::ProjectHookType.connection_type, null: true

      alias_method :project, :object

      when_single do
        argument :id, Types::GlobalIDType[::ProjectHook],
          required: true,
          description: 'ID of the project webhook.'
      end

      def resolve(**args)
        hooks = project.hooks

        return hooks unless args[:id].present?

        hooks.id_in(args[:id].model_id)
      end
    end
  end
end
