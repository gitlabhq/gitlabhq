# frozen_string_literal: true

module Issuables
  class BaseFilter
    attr_reader :params

    FILTER_NONE = 'none'
    FILTER_ANY = 'any'

    def initialize(params:, or_filters_enabled: false)
      @params = params
      @or_filters_enabled = or_filters_enabled
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

    def or_filters_enabled?
      @or_filters_enabled
    end
  end
end
