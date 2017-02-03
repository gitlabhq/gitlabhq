module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
      @application_setting.update(@params)
    end
  end
end
