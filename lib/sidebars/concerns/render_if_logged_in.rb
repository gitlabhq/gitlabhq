# frozen_string_literal: true

module Sidebars
  module Concerns
    module RenderIfLoggedIn
      def render?
        !!context.current_user
      end
    end
  end
end
