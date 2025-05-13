# frozen_string_literal: true

module Issuables
  class BaseFilter
    FILTER_NONE = 'none'
    FILTER_ANY = 'any'

    def initialize(params:, parent: nil, current_user: nil)
      @params = params
      @parent = parent
      @current_user = current_user
    end

    def filter
      raise NotImplementedError
    end

    private

    attr_reader :params, :parent, :current_user

    def or_params
      params[:or]
    end

    def not_params
      params[:not]
    end
  end
end
