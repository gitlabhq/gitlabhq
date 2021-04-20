# frozen_string_literal: true

module ApplicationSettings
  class BaseService < ::BaseService
    def initialize(application_setting, user, params = {})
      @application_setting = application_setting
      @current_user = user
      @params = params.dup
    end
  end
end
