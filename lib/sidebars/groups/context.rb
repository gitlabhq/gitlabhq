# frozen_string_literal: true

module Sidebars
  module Groups
    class Context < ::Sidebars::Context
      def initialize(current_user:, container:, **args)
        super(current_user: current_user, container: container, group: container, **args)
      end
    end
  end
end
