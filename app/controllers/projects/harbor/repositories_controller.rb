# frozen_string_literal: true

module Projects
  module Harbor
    class RepositoriesController < ::Projects::Harbor::ApplicationController
      include ::Harbor::Repository

      private

      def container
        @project
      end
    end
  end
end
