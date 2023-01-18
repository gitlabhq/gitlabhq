# frozen_string_literal: true

module Achievements
  class BaseService < ::BaseContainerService
    def initialize(namespace:, current_user: nil, params: {})
      @namespace = namespace
      super(container: namespace, current_user: current_user, params: params)
    end

    private

    def allowed?
      current_user&.can?(:admin_achievement, @namespace)
    end

    def error(message)
      ServiceResponse.error(message: Array(message))
    end
  end
end
