module Projects
  module Boards
    class ApplicationController < Projects::ApplicationController
      respond_to :json

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      private

      def record_not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end
    end
  end
end
