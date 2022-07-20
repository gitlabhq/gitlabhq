# frozen_string_literal: true

module Projects
  module Harbor
    class TagsController < ::Projects::Harbor::ApplicationController
      include ::Harbor::Tag

      private

      def container
        @project
      end
    end
  end
end
