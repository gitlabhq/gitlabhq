# frozen_string_literal: true

module StrongPaginationParams
  extend ActiveSupport::Concern

  PAGINATION_PARAMS = [:page, :per_page, :limit, :sort, :order_by, :pagination].freeze

  def pagination_params
    params.permit(PAGINATION_PARAMS)
  end
end
