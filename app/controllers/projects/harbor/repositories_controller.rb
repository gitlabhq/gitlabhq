# frozen_string_literal: true

module Projects
  module Harbor
    class RepositoriesController < ::Projects::Harbor::ApplicationController
      def show
        render :index
      end
    end
  end
end
