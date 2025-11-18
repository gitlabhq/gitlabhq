# frozen_string_literal: true

module Types
  module WebHooks
    class ProjectHookType < BaseObject
      graphql_name 'ProjectHook'

      authorize :read_web_hook

      include Types::WebHooks::HookType

      field :id, Types::GlobalIDType[::ProjectHook],
        null: false,
        description: 'ID of the webhook.'
    end
  end
end

Types::WebHooks::ProjectHookType.prepend_mod_with('Types::WebHooks::ProjectHookType')
