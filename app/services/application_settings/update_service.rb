module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
      # Repository size limit comes as MB from the view
      limit = @params.delete(:repository_size_limit)
      @application_setting.repository_size_limit = Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

      @application_setting.update(@params)
    end
  end
end
