# frozen_string_literal: true

module GoogleCloud
  class SetupCloudsqlInstanceService < ::GoogleCloud::BaseService
    INSTANCE_STATE_RUNNABLE = 'RUNNABLE'
    OPERATION_STATE_DONE = 'DONE'
    DEFAULT_DATABASE_NAME = 'main_db'
    DEFAULT_DATABASE_USER = 'main_user'

    def execute
      return error('Unauthorized user') unless Ability.allowed?(current_user, :admin_project_google_cloud, project)

      get_instance_response = google_api_client.get_cloudsql_instance(gcp_project_id, instance_name)

      if get_instance_response.state != INSTANCE_STATE_RUNNABLE
        return error("CloudSQL instance not RUNNABLE: #{get_instance_response.to_json}")
      end

      database_response = google_api_client.create_cloudsql_database(gcp_project_id, instance_name, database_name)

      if database_response.status != OPERATION_STATE_DONE
        return error("Database creation failed: #{database_response.to_json}")
      end

      user_response = google_api_client.create_cloudsql_user(gcp_project_id, instance_name, username, password)

      if user_response.status != OPERATION_STATE_DONE
        return error("User creation failed: #{user_response.to_json}")
      end

      primary_ip_address = get_instance_response.ip_addresses.first.ip_address
      connection_name = get_instance_response.connection_name

      save_ci_var('GCP_PROJECT_ID', gcp_project_id)
      save_ci_var('GCP_CLOUDSQL_INSTANCE_NAME', instance_name)
      save_ci_var('GCP_CLOUDSQL_CONNECTION_NAME', connection_name)
      save_ci_var('GCP_CLOUDSQL_PRIMARY_IP_ADDRESS', primary_ip_address)
      save_ci_var('GCP_CLOUDSQL_VERSION', database_version)
      save_ci_var('GCP_CLOUDSQL_DATABASE_NAME', database_name)
      save_ci_var('GCP_CLOUDSQL_DATABASE_USER', username)
      save_ci_var('GCP_CLOUDSQL_DATABASE_PASS', password, true)

      success
    rescue Google::Apis::Error => err
      error(message: err.to_json)
    end

    private

    def instance_name
      @params[:instance_name]
    end

    def database_version
      @params[:database_version]
    end

    def database_name
      @params.fetch(:database_name, DEFAULT_DATABASE_NAME)
    end

    def username
      @params.fetch(:username, DEFAULT_DATABASE_USER)
    end

    def password
      SecureRandom.hex(16)
    end

    def save_ci_var(key, value, is_masked = false)
      create_or_replace_project_vars(environment_name, key, value, @params[:is_protected], is_masked)
    end
  end
end
