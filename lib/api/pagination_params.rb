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
          optional :page, type: Integer, default: 1, desc: 'Current page number', documentation: { example: 1 }
          optional :per_page, type: Integer, default: 20,
            desc: 'Number of items per page', except_values: [0], documentation: { example: 20 }
        end

        def verify_pagination_params!
          return if Feature.disabled?(:only_positive_pagination_values)

          page = begin
            Integer(params[:page])
          rescue ArgumentError, TypeError
            nil
          end

          return render_structured_api_error!({ error: 'page does not have a valid value' }, 400) if page&.< 1

          per_page = begin
            Integer(params[:per_page])
          rescue ArgumentError, TypeError
            nil
          end

          return render_structured_api_error!({ error: 'per_page does not have a valid value' }, 400) if per_page&.< 1
        end
      end
    end
  end
end
