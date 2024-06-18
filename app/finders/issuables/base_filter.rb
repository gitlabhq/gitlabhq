# frozen_string_literal: true

module Issuables
  class BaseFilter
    attr_reader :params

    FILTER_NONE = 'none'
    FILTER_ANY = 'any'

    def initialize(params:)
      @params = params
    end

    def filter
      raise NotImplementedError
    end

    private

    def or_params
      params[:or]
    end

    def not_params
      params[:not]
    end
  end
end
