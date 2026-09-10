# frozen_string_literal: true

module Gitlab
  module WebHooks
    module DuoFlowCallback
      class << self
        def available?(container)
          return false unless container
          return false unless Feature.enabled?(:duo_flow_callback_hooks, container.root_ancestor)

          duo_agent_platform_available?(container)
        end

        private

        def duo_agent_platform_available?(_container)
          false
        end
      end
    end
  end
end

Gitlab::WebHooks::DuoFlowCallback.singleton_class.prepend_mod_with('Gitlab::WebHooks::DuoFlowCallback')
