# frozen_string_literal: true

module JiraConnectInstallations
  class UpdateService
    def self.execute(installation, jira_user, update_params, skip_jira_admin_check: false)
      new(installation, jira_user, update_params, skip_jira_admin_check: skip_jira_admin_check).execute
    end

    def initialize(installation, jira_user, update_params, skip_jira_admin_check: false)
      @installation = installation
      @jira_user = jira_user
      @update_params = update_params
      @skip_jira_admin_check = skip_jira_admin_check
    end

    def execute
      return forbidden_error unless can_administer_jira?
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

    def forbidden_error
      ServiceResponse.error(
        message: s_('JiraConnect|The Jira user is not a site or organization administrator. ' \
          'Check the permissions in Jira and try again.'),
        reason: :forbidden
      )
    end

    def can_administer_jira?
      @skip_jira_admin_check || @jira_user&.jira_admin?
    end
  end
end
