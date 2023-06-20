# frozen_string_literal: true

require 'securerandom'
require 'google/apis/compute_v1'
require 'google/apis/container_v1'
require 'google/apis/container_v1beta1'
require 'google/apis/cloudbilling_v1'
require 'google/apis/cloudresourcemanager_v1'
require 'google/apis/iam_v1'
require 'google/apis/serviceusage_v1'
require 'google/apis/sqladmin_v1beta4'

module GoogleApi
  module CloudPlatform
    class Client < GoogleApi::Auth
      SCOPE = 'https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/service.management'
      LEAST_TOKEN_LIFE_TIME = 10.minutes
      ROLES_LIST = %w[roles/iam.serviceAccountUser roles/artifactregistry.admin roles/cloudbuild.builds.builder roles/run.admin roles/storage.admin roles/cloudsql.client roles/browser].freeze
      REVOKE_URL = 'https://oauth2.googleapis.com/revoke'

      class << self
        def session_key_for_token
          :cloud_platform_access_token
        end

        def session_key_for_expires_at
          :cloud_platform_expires_at
        end

        def new_session_key_for_redirect_uri
          SecureRandom.hex.tap do |state|
            yield session_key_for_redirect_uri(state)
          end
        end

        def session_key_for_redirect_uri(state)
          "cloud_platform_second_redirect_uri_#{state}"
        end
      end

      def scope
        SCOPE
      end

      def validate_token(expires_at)
        return false unless access_token
        return false unless expires_at

        # Making sure that the token will have been still alive during the cluster creation.
        return false if token_life_time(expires_at) < LEAST_TOKEN_LIFE_TIME

        true
      end

      def list_projects
        result = []

        response = cloud_resource_manager_service.fetch_all(items: :projects) do |token|
          cloud_resource_manager_service.list_projects
        end

        # Google API results are paged by default, so we need to iterate through
        response.each do |project|
          result.append(project)
        end

        result.sort_by(&:project_id)
      end

      def create_service_account(gcp_project_id, display_name, description)
        name = "projects/#{gcp_project_id}"

        # initialize google iam service
        service = Google::Apis::IamV1::IamService.new
        service.authorization = access_token

        # generate account id
        random_account_id = "gitlab-" + SecureRandom.hex(11)

        body_params = { account_id: random_account_id,
                        service_account: { display_name: display_name,
                                           description: description } }

        request_body = Google::Apis::IamV1::CreateServiceAccountRequest.new(**body_params)
        service.create_service_account(name, request_body)
      end

      def create_service_account_key(gcp_project_id, service_account_id)
        service = Google::Apis::IamV1::IamService.new
        service.authorization = access_token

        name = "projects/#{gcp_project_id}/serviceAccounts/#{service_account_id}"
        request_body = Google::Apis::IamV1::CreateServiceAccountKeyRequest.new
        service.create_service_account_key(name, request_body)
      end

      def grant_service_account_roles(gcp_project_id, email)
        body = policy_request_body(gcp_project_id, email)
        cloud_resource_manager_service.set_project_iam_policy(gcp_project_id, body)
      end

      def enable_cloud_run(gcp_project_id)
        enable_service(gcp_project_id, 'run.googleapis.com')
      end

      def enable_artifacts_registry(gcp_project_id)
        enable_service(gcp_project_id, 'artifactregistry.googleapis.com')
      end

      def enable_cloud_build(gcp_project_id)
        enable_service(gcp_project_id, 'cloudbuild.googleapis.com')
      end

      def enable_cloud_sql_admin(gcp_project_id)
        enable_service(gcp_project_id, 'sqladmin.googleapis.com')
      end

      def enable_compute(gcp_project_id)
        enable_service(gcp_project_id, 'compute.googleapis.com')
      end

      def enable_service_networking(gcp_project_id)
        enable_service(gcp_project_id, 'servicenetworking.googleapis.com')
      end

      def enable_vision_api(gcp_project_id)
        enable_service(gcp_project_id, 'vision.googleapis.com')
      end

      def revoke_authorizations
        uri = URI(REVOKE_URL)
        Gitlab::HTTP.post(uri, body: { 'token' => access_token })
      end

      def list_cloudsql_databases(gcp_project_id, instance_name)
        sql_admin_service.list_databases(gcp_project_id, instance_name, options: user_agent_header)
      end

      def create_cloudsql_database(gcp_project_id, instance_name, database_name)
        database = Google::Apis::SqladminV1beta4::Database.new(name: database_name)
        sql_admin_service.insert_database(gcp_project_id, instance_name, database)
      end

      def list_cloudsql_users(gcp_project_id, instance_name)
        sql_admin_service.list_users(gcp_project_id, instance_name, options: user_agent_header)
      end

      def create_cloudsql_user(gcp_project_id, instance_name, username, password)
        user = Google::Apis::SqladminV1beta4::User.new
        user.name = username
        user.password = password
        sql_admin_service.insert_user(gcp_project_id, instance_name, user)
      end

      def get_cloudsql_instance(gcp_project_id, instance_name)
        sql_admin_service.get_instance(gcp_project_id, instance_name)
      end

      def create_cloudsql_instance(gcp_project_id, instance_name, root_password, database_version, region, tier)
        database_instance = Google::Apis::SqladminV1beta4::DatabaseInstance.new(
          name: instance_name,
          root_password: root_password,
          database_version: database_version,
          region: region,
          settings: Google::Apis::SqladminV1beta4::Settings.new(tier: tier)
        )

        sql_admin_service.insert_instance(gcp_project_id, database_instance)
      end

      private

      def enable_service(gcp_project_id, service_name)
        name = "projects/#{gcp_project_id}/services/#{service_name}"
        service = Google::Apis::ServiceusageV1::ServiceUsageService.new
        service.authorization = access_token
        service.enable_service(name)
      end

      def token_life_time(expires_at)
        DateTime.strptime(expires_at, '%s').to_time.utc - Time.now.utc
      end

      def user_agent_header
        Google::Apis::RequestOptions.new.tap do |options|
          options.header = { 'User-Agent': "GitLab/#{Gitlab::VERSION.match('(\d+\.\d+)').captures.first} (GPN:GitLab;)" }
        end
      end

      def policy_request_body(gcp_project_id, email)
        policy = cloud_resource_manager_service.get_project_iam_policy(gcp_project_id)
        policy.bindings = policy.bindings + additional_policy_bindings("serviceAccount:#{email}")

        Google::Apis::CloudresourcemanagerV1::SetIamPolicyRequest.new(policy: policy)
      end

      def additional_policy_bindings(member)
        ROLES_LIST.map do |role|
          Google::Apis::CloudresourcemanagerV1::Binding.new(role: role, members: [member])
        end
      end

      def cloud_resource_manager_service
        @gpc_service ||= Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService.new.tap { |s| s.authorization = access_token }
      end

      def sql_admin_service
        @sql_admin_service ||= Google::Apis::SqladminV1beta4::SQLAdminService.new.tap { |s| s.authorization = access_token }
      end
    end
  end
end
