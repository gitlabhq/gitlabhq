module ApplicationSettings
  class BaseService < ::BaseService
    attr_accessor :application_setting, :current_user, :params

    def initialize(application_setting, user, params = {})
      @application_setting, @current_user, @params = application_setting, user, params.dup
    end
  end
end
