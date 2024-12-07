# frozen_string_literal: true

module Projects
  module GoogleCloud
    class DatabasesController < Projects::GoogleCloud::BaseController
      before_action :validate_gcp_token!
      before_action :validate_product, only: :new

      def index
        js_data = {
          configurationUrl: project_google_cloud_configuration_path(project),
          deploymentsUrl: project_google_cloud_deployments_path(project),
          databasesUrl: project_google_cloud_databases_path(project),
          cloudsqlPostgresUrl: new_project_google_cloud_database_path(project, :postgres),
          cloudsqlMysqlUrl: new_project_google_cloud_database_path(project, :mysql),
          cloudsqlSqlserverUrl: new_project_google_cloud_database_path(project, :sqlserver),
          cloudsqlInstances: ::CloudSeed::GoogleCloud::GetCloudsqlInstancesService.new(project).execute,
          emptyIllustrationUrl:
            ActionController::Base.helpers.image_path('illustrations/empty-state/empty-pipeline-md.svg')
        }

        @js_data = Gitlab::Json.dump(js_data)

        track_event(:render_page)
      end

      def new
        product = permitted_params[:product].to_sym

        @title = title(product)

        js_data = {
          gcpProjects: gcp_projects,
          refs: refs,
          cancelPath: project_google_cloud_databases_path(project),
          formTitle: form_title(product),
          formDescription: description(product),
          databaseVersions: Projects::GoogleCloud::CloudsqlHelper::VERSIONS[product],
          tiers: Projects::GoogleCloud::CloudsqlHelper::TIERS
        }

        @js_data = Gitlab::Json.dump(js_data)

        track_event(:render_form)
        render template: 'projects/google_cloud/databases/cloudsql_form', formats: :html
      end

      def create
        enable_response = ::CloudSeed::GoogleCloud::EnableCloudsqlService
                            .new(project, current_user, enable_service_params)
                            .execute

        if enable_response[:status] == :error
          track_event(:error_enable_cloudsql_services)
          flash[:alert] = error_message(enable_response[:message])
        else
          create_response = ::CloudSeed::GoogleCloud::CreateCloudsqlInstanceService
                              .new(project, current_user, create_service_params)
                              .execute

          if create_response[:status] == :error
            track_event(:error_create_cloudsql_instance)
            flash[:warning] = error_message(create_response[:message])
          else
            track_event(:create_cloudsql_instance, permitted_params_create.to_s)
            flash[:notice] = success_message
          end
        end

        redirect_to project_google_cloud_databases_path(project)
      end

      private

      def permitted_params_create
        params.permit(:gcp_project, :ref, :database_version, :tier)
      end

      def enable_service_params
        {
          google_oauth2_token: token_in_session,
          gcp_project_id: permitted_params_create[:gcp_project],
          environment_name: permitted_params_create[:ref]
        }
      end

      def create_service_params
        {
          google_oauth2_token: token_in_session,
          gcp_project_id: permitted_params_create[:gcp_project],
          environment_name: permitted_params_create[:ref],
          database_version: permitted_params_create[:database_version],
          tier: permitted_params_create[:tier]
        }
      end

      def error_message(message)
        format(s_("CloudSeed|Google Cloud Error - %{message}"), message: message)
      end

      def success_message
        s_('CloudSeed|Cloud SQL instance creation request successful. Expected resolution time is ~5 minutes.')
      end

      def validate_product
        not_found unless permitted_params[:product].in?(%w[postgres mysql sqlserver])
      end

      def permitted_params
        params.permit(:product)
      end

      def title(product)
        case product
        when :postgres
          s_('CloudSeed|Create Postgres Instance')
        when :mysql
          s_('CloudSeed|Create MySQL Instance')
        else
          s_('CloudSeed|Create MySQL Instance')
        end
      end

      def form_title(product)
        case product
        when :postgres
          s_('CloudSeed|Cloud SQL for Postgres')
        when :mysql
          s_('CloudSeed|Cloud SQL for MySQL')
        else
          s_('CloudSeed|Cloud SQL for SQL Server')
        end
      end

      def description(product)
        case product
        when :postgres
          s_('CloudSeed|Cloud SQL instances are fully managed, relational PostgreSQL databases. ' \
            'Google handles replication, patch management, and database management ' \
            'to ensure availability and performance.')
        when :mysql
          s_('Cloud SQL instances are fully managed, relational MySQL databases. ' \
            'Google handles replication, patch management, and database management ' \
            'to ensure availability and performance.')
        else
          s_('Cloud SQL instances are fully managed, relational SQL Server databases. ' \
            'Google handles replication, patch management, and database management ' \
            'to ensure availability and performance.')
        end
      end
    end
  end
end
