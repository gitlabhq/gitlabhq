module API
  # Concern for declare pagination params.
  #
  # @example
  #   class CustomApiResource < Grape::API
  #     include PaginationParams
  #
  #     params do
  #       use :pagination
  #     end
  #   end
  module PaginationParams
    extend ActiveSupport::Concern

    included do
      helpers do
        params :pagination do
          optional :page, type: Integer, desc: 'Current page number'
          optional :per_page, type: Integer, desc: 'Number of items per page'
        end
      end
    end
  end
end
