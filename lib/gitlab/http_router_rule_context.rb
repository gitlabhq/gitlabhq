# frozen_string_literal: true

module Gitlab
  module HttpRouterRuleContext
    extend ActiveSupport::Concern

    # This module is used to log the headers set by the HTTP Router.
    # Refer: https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/src/header.ts
    # to obtain the list of headers.
    #
    # Usage:
    # 1. Include this concern in base controller:
    #      include Gitlab::HttpRouterRuleContext
    #    Or, in the API layer as a helper
    #      helpers Gitlab::HttpRouterRuleContext
    #
    # 2. Use the `http_router_rule_context` method when pushing to Gitlab::ApplicationContext:
    #    Gitlab::ApplicationContext.push(**router_rule_context)

    private

    def http_router_rule_context
      {
        http_router_rule_action: request.headers['X-Gitlab-Http-Router-Rule-Action'],
        http_router_rule_type: request.headers['X-Gitlab-Http-Router-Rule-Type']
      }
    end
  end
end
