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

    HOURS_TO_WAIT_FOR_BACKFILL = 1

    # namespace_id - id of the Group or personal (user) Namespace to provision.
    # project_id - for personal namespaces only: the initiating project, used as
    #   the container for the CI export variable (user namespaces have no CI
    #   variables of their own).
    def perform(user_id, namespace_id, project_id = nil)
      user = User.find_by_id(user_id)
      namespace = Namespace.find_by_id(namespace_id)

      unless user && namespace
        log_missing_entities(user, namespace, user_id, namespace_id)
        return
      end

      client = O11yProvisioningClient.new
      result = client.provision_group(namespace, user)

      if result[:success]
        handle_successful_api_call(namespace, result[:settings_params], namespace_id, user_id, user, project_id)
      else
        log_completion(:api_failed, namespace_id)
        log_error(result[:error], namespace_id, user_id)
      end
    end

    private

    def handle_successful_api_call(namespace, settings_params, namespace_id, user_id, user, project_id)
      setting = namespace.observability_group_o11y_setting || namespace.build_observability_group_o11y_setting
      result = ::Observability::GroupO11ySettingsUpdateService.new.execute(setting, settings_params)

      if result.success?
        backfill_existing_pipelines(namespace) if add_ci_variable(namespace, user, project_id)
        log_completion(:success, namespace_id)
      else
        log_completion(:database_failed, namespace_id, result.message)
        log_error('Failed to save observability group setting after successful API call', namespace_id, user_id,
          result.message)
      end
    end

    def add_ci_variable(namespace, user, project_id)
      container = ci_variable_container(namespace, project_id)

      unless container
        log_error(
          'No CI variable container available for observability export',
          namespace.id,
          user.id,
          "project_id: #{project_id.inspect}"
        )
        return false
      end

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
        container: container,
        current_user: user,
        params: params
      ).execute

      if result
        true
      else
        log_error(
          'Failed to create CI variable for observability export',
          namespace.id,
          user.id,
          container.errors.full_messages.join(', ')
        )
        false
      end
    end

    # Groups hold the variable themselves; personal namespaces have no CI
    # variables, so the variable goes on the initiating project instead.
    def ci_variable_container(namespace, project_id)
      return namespace if namespace.is_a?(Group)
      return unless project_id

      project = Project.find_by_id(project_id)
      return unless project && project.namespace_id == namespace.id

      project
    end

    def backfill_existing_pipelines(namespace)
      # GroupExportWorker resolves descendant groups/projects and is a no-op for
      # personal namespaces; the initiating project's pipelines export from the
      # next run onward via the project CI variable.
      return unless namespace.is_a?(Group)

      Ci::Observability::GroupExportWorker.perform_in(HOURS_TO_WAIT_FOR_BACKFILL.hour, namespace.id)
    end

    def log_completion(status, namespace_id, error_message = nil)
      log_extra_metadata_on_done(:status, status.to_s)
      log_extra_metadata_on_done(:namespace_id, namespace_id)
      log_extra_metadata_on_done(:error, error_message) if error_message
    end

    def log_missing_entities(user, namespace, user_id, namespace_id)
      missing_entities = []
      missing_entities << 'user' unless user
      missing_entities << 'namespace' unless namespace

      message = "Missing required entities: #{missing_entities.join(', ')}"
      log_error(message, namespace_id, user_id)
    end

    def log_error(message, namespace_id, user_id, error = nil)
      Gitlab::AppLogger.error(
        message: message,
        namespace_id: namespace_id,
        user_id: user_id,
        error: error
      )
    end
  end
end
