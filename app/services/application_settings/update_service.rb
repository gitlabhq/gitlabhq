module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
      # Repository size limit comes as MB from the view
      assign_repository_size_limit_as_bytes(@application_setting)

      @application_setting.update(@params)
    end
  end
end
