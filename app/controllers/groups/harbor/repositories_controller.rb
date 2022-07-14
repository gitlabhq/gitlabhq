# frozen_string_literal: true

module Groups
  module Harbor
    class RepositoriesController < ::Groups::Harbor::ApplicationController
      include ::Harbor::Repository

      private

      def container
        @group
      end
    end
  end
end
