# frozen_string_literal: true

module ApplicationSettings
  class BaseService < ::BaseService
    def initialize(application_setting, user, params = {})
      @application_setting, @current_user, @params = application_setting, user, params.dup
    end
  end
end
