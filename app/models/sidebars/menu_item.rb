# frozen_string_literal: true

module Sidebars
  class MenuItem
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Routing
    include GitlabRoutingHelper
    include Gitlab::Allowable
    include ::Sidebars::HasIcon
    include ::Sidebars::HasHint
    include ::Sidebars::Renderable
    include ::Sidebars::ContainerWithHtmlOptions
    include ::Sidebars::HasActiveRoutes

    attr_reader :context

    def initialize(context)
      @context = context
    end
  end
end
