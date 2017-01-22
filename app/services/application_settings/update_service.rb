module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
      # Repository size limit comes as MB from the view
      limit = @params.delete(:repository_size_limit)
      @application_setting.repository_size_limit = (limit.to_i.megabytes if limit.present?)

      @application_setting.update(@params)
    end
  end
end
