# frozen_string_literal: true

module Observability
  class CreateGroupO11ySettingWorker
    include ApplicationWorker

    deduplicate :until_executed
    idempotent!
    data_consistency :sticky
    feature_category :observability
    urgency :low
    defer_on_database_health_signal :gitlab_main
    worker_resource_boundary :cpu
    weight 2

    sidekiq_options retry: 3
    worker_has_external_dependencies!

    def perform(user_id, group_id)
      user = User.find_by_id(user_id)
      group = Group.find_by_id(group_id)

      unless user && group
        log_missing_entities(user, group, user_id, group_id)
        return
      end

      if group.observability_group_o11y_setting.present?
        log_completion(:skipped, group_id)
        return
      end

      client = O11yProvisioningClient.new
      result = client.provision_group(group, user)

      if result[:success]
        handle_successful_api_call(group, result[:settings_params], group_id, user_id, user)
      else
        log_completion(:api_failed, group_id)
        log_error(result[:error], group_id, user_id)
      end
    end

    private

    def handle_successful_api_call(group, settings_params, group_id, user_id, user)
      setting = group.build_observability_group_o11y_setting
      result = ::Observability::GroupO11ySettingsUpdateService.new.execute(setting, settings_params)

      if result.success?
        add_ci_variable(group, user)
        log_completion(:success, group_id)
      else
        log_completion(:database_failed, group_id, result.message)
        log_error('Failed to save observability group setting after successful API call', group_id, user_id,
          result.message)
      end
    end

    def add_ci_variable(group, user)
      params = {
        variables_attributes: [
          {
            key: 'GITLAB_OBSERVABILITY_EXPORT',
            value: 'traces,metrics,logs',
            variable_type: 'env_var',
            protected: false,
            masked: false,
            raw: false
          }
        ]
      }

      result = Ci::ChangeVariablesService.new(
        container: group,
        current_user: user,
        params: params
      ).execute

      return if result

      log_error(
        'Failed to create CI variable for observability export',
        group.id,
        user.id,
        group.errors.full_messages.join(', ')
      )
    end

    def log_completion(status, group_id, error_message = nil)
      log_extra_metadata_on_done(:status, status.to_s)
      log_extra_metadata_on_done(:group_id, group_id)
      log_extra_metadata_on_done(:error, error_message) if error_message
    end

    def log_missing_entities(user, group, user_id, group_id)
      missing_entities = []
      missing_entities << 'user' unless user
      missing_entities << 'group' unless group

      message = "Missing required entities: #{missing_entities.join(', ')}"
      log_error(message, group_id, user_id)
    end

    def log_error(message, group_id, user_id, error = nil)
      Gitlab::AppLogger.error(
        message: message,
        group_id: group_id,
        user_id: user_id,
        error: error
      )
    end
  end
end
