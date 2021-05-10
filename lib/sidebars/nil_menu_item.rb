# frozen_string_literal: true

module Sidebars
  class NilMenuItem < MenuItem
    extend ::Gitlab::Utils::Override

    def initialize(item_id:)
      super(item_id: item_id, title: nil, link: nil, active_routes: {})
    end

    override :render?
    def render?
      false
    end
  end
end
