# frozen_string_literal: true

module Sidebars
  class MenuItem
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Routing
    include GitlabRoutingHelper
    include Gitlab::Allowable
    include ::Sidebars::Concerns::HasIcon
    include ::Sidebars::Concerns::HasHint
    include ::Sidebars::Concerns::Renderable
    include ::Sidebars::Concerns::ContainerWithHtmlOptions
    include ::Sidebars::Concerns::HasActiveRoutes

    attr_reader :context

    def initialize(context)
      @context = context
    end
  end
end
