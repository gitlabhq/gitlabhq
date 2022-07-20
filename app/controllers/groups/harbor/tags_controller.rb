# frozen_string_literal: true

module Groups
  module Harbor
    class TagsController < ::Groups::Harbor::ApplicationController
      include ::Harbor::Tag

      private

      def container
        @group
      end
    end
  end
end
