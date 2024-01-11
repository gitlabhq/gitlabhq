# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class SetupCloudsqlInstanceService < ::CloudSeed::GoogleCloud::BaseService
      INSTANCE_STATE_RUNNABLE = 'RUNNABLE'
      OPERATION_STATE_DONE = 'DONE'
      DEFAULT_DATABASE_NAME = 'main_db'
      DEFAULT_DATABASE_USER = 'main_user'

      def execute
        return error('Unauthorized user') unless Ability.allowed?(current_user, :admin_project_google_cloud, project)

        get_instance_response = google_api_client.get_cloudsql_instance(gcp_project_id, instance_name)

        if get_instance_response.state != INSTANCE_STATE_RUNNABLE
          return error("CloudSQL instance not RUNNABLE: #{Gitlab::Json.dump(get_instance_response)}")
        end

        save_instance_ci_vars(get_instance_response)

        list_database_response = google_api_client.list_cloudsql_databases(gcp_project_id, instance_name)
        list_user_response = google_api_client.list_cloudsql_users(gcp_project_id, instance_name)

        existing_database = list_database_response.items.find { |database| database.name == database_name }
        existing_user = list_user_response.items.find { |user| user.name == username }

        if existing_database && existing_user
          save_database_ci_vars
          save_user_ci_vars(existing_user)
          return success
        end

        database_response = execute_database_setup(existing_database)
        return database_response if database_response[:status] == :error

        save_database_ci_vars

        user_response = execute_user_setup(existing_user)
        return user_response if user_response[:status] == :error

        save_user_ci_vars(existing_user)

        success
      rescue Google::Apis::Error => err
        error(message: Gitlab::Json.dump(err))
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
        @password ||= SecureRandom.hex(16)
      end

      def save_ci_var(key, value, is_masked = false)
        create_or_replace_project_vars(environment_name, key, value, @params[:is_protected], is_masked)
      end

      def save_instance_ci_vars(cloudsql_instance)
        primary_ip_address = cloudsql_instance.ip_addresses.first.ip_address
        connection_name = cloudsql_instance.connection_name

        save_ci_var('GCP_PROJECT_ID', gcp_project_id)
        save_ci_var('GCP_CLOUDSQL_INSTANCE_NAME', instance_name)
        save_ci_var('GCP_CLOUDSQL_CONNECTION_NAME', connection_name)
        save_ci_var('GCP_CLOUDSQL_PRIMARY_IP_ADDRESS', primary_ip_address)
        save_ci_var('GCP_CLOUDSQL_VERSION', database_version)
      end

      def save_database_ci_vars
        save_ci_var('GCP_CLOUDSQL_DATABASE_NAME', database_name)
      end

      def save_user_ci_vars(user_exists)
        save_ci_var('GCP_CLOUDSQL_DATABASE_USER', username)
        save_ci_var('GCP_CLOUDSQL_DATABASE_PASS', user_exists ? user_exists.password : password, true)
      end

      def execute_database_setup(database_exists)
        return success if database_exists

        database_response = google_api_client.create_cloudsql_database(gcp_project_id, instance_name, database_name)

        if database_response.status != OPERATION_STATE_DONE
          return error("Database creation failed: #{Gitlab::Json.dump(database_response)}")
        end

        success
      end

      def execute_user_setup(existing_user)
        return success if existing_user

        user_response = google_api_client.create_cloudsql_user(gcp_project_id, instance_name, username, password)

        if user_response.status != OPERATION_STATE_DONE
          return error("User creation failed: #{Gitlab::Json.dump(user_response)}")
        end

        success
      end
    end
  end
end
