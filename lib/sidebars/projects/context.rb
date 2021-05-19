# frozen_string_literal: true

module Sidebars
  module Projects
    class Context < ::Sidebars::Context
      def initialize(current_user:, container:, **args)
        super(current_user: current_user, container: container, project: container, **args)
      end
    end
  end
end
