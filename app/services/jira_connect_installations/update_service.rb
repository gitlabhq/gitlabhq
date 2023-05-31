# frozen_string_literal: true

module JiraConnectInstallations
  class UpdateService
    def self.execute(installation, update_params)
      new(installation, update_params).execute
    end

    def initialize(installation, update_params)
      @installation = installation
      @update_params = update_params
    end

    def execute
      return update_error unless @installation.update(@update_params)

      if @installation.instance_url?
        hook_result = ProxyLifecycleEventService.execute(@installation, :installed, @installation.instance_url)

        if instance_url_changed? && hook_result.error?
          @installation.update!(instance_url: @installation.instance_url_before_last_save)

          return instance_installation_creation_error(hook_result.message)
        end
      end

      send_uninstalled_hook if instance_url_changed? && @installation.instance_url.blank?

      ServiceResponse.new(status: :success)
    end

    private

    def instance_url_changed?
      @installation.instance_url_before_last_save != @installation.instance_url
    end

    def send_uninstalled_hook
      return if @installation.instance_url_before_last_save.blank?

      JiraConnect::SendUninstalledHookWorker.perform_async(
        @installation.id,
        @installation.instance_url_before_last_save
      )
    end

    def instance_installation_creation_error(error_message)
      message = if error_message[:type] == :response_error
                  "Could not be installed on the instance. Error response code #{error_message[:code]}"
                else
                  'Could not be installed on the instance. Network error'
                end

      ServiceResponse.error(message: message)
    end

    def update_error
      ServiceResponse.error(message: @installation.errors)
    end
  end
end
