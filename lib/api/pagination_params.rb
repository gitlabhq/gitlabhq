# frozen_string_literal: true

module API
  # Concern for declare pagination params.
  #
  # @example
  #   class CustomApiResource < Grape::API::Instance
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
          optional :page, type: Integer, default: 1, desc: 'Current page number'
          optional :per_page, type: Integer, default: 20, desc: 'Number of items per page'
        end
      end
    end
  end
end
