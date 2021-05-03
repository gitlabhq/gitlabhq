# frozen_string_literal: true

module Issuables
  class BaseFilter
    attr_reader :issuables, :params

    def initialize(issuables, params:, or_filters_enabled: false)
      @issuables = issuables
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
