# frozen_string_literal: true

# Copies system dashboard definition in .yml file into designated
# .yml file inside `.gitlab/dashboards`
module Metrics
  module Dashboard
    class CloneDashboardService < ::BaseService
      include Stepable
      include Gitlab::Utils::StrongMemoize

      ALLOWED_FILE_TYPE = '.yml'
      USER_DASHBOARDS_DIR = ::Gitlab::Metrics::Dashboard::RepoDashboardFinder::DASHBOARD_ROOT
      SEQUENCES = {
        ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => [
          ::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
          ::Gitlab::Metrics::Dashboard::Stages::CustomMetricsInserter
        ].freeze,

        ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH => [
          ::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter
        ].freeze
      }.freeze

      steps :check_push_authorized,
            :check_branch_name,
            :check_file_type,
            :check_dashboard_template,
            :create_file,
            :refresh_repository_method_caches

      def execute
        execute_steps
      end

      private

      def check_push_authorized(result)
        return error(_('You are not allowed to push into this branch. Create another branch or open a merge request.'), :forbidden) unless push_authorized?

        success(result)
      end

      def check_branch_name(result)
        return error(_('There was an error creating the dashboard, branch name is invalid.'), :bad_request) unless valid_branch_name?
        return error(_('There was an error creating the dashboard, branch named: %{branch} already exists.') % { branch: params[:branch] }, :bad_request) unless new_or_default_branch?

        success(result)
      end

      def check_file_type(result)
        return error(_('The file name should have a .yml extension'), :bad_request) unless target_file_type_valid?

        success(result)
      end

      # Only allow out of the box metrics dashboards to be cloned. This can be
      # changed to allow cloning of any metrics dashboard, if desired.
      # However, only metrics dashboards should be allowed. If any file is
      # allowed to be cloned, this will become a security risk.
      def check_dashboard_template(result)
        return error(_('Not found.'), :not_found) unless dashboard_service&.out_of_the_box_dashboard?

        success(result)
      end

      def create_file(result)
        create_file_response = ::Files::CreateService.new(project, current_user, dashboard_attrs).execute

        if create_file_response[:status] == :success
          success(result.merge(create_file_response))
        else
          wrap_error(create_file_response)
        end
      end

      def refresh_repository_method_caches(result)
        repository.refresh_method_caches([:metrics_dashboard])

        success(result.merge(http_status: :created, dashboard: dashboard_details))
      end

      def dashboard_service
        strong_memoize(:dashboard_service) do
          Gitlab::Metrics::Dashboard::ServiceSelector.call(dashboard_service_options)
        end
      end

      def dashboard_attrs
        {
          commit_message: params[:commit_message],
          file_path: new_dashboard_path,
          file_content: new_dashboard_content,
          encoding: 'text',
          branch_name: branch,
          start_branch: repository.branch_exists?(branch) ? branch : project.default_branch
        }
      end

      def dashboard_details
        {
          path: new_dashboard_path,
          display_name: ::Metrics::Dashboard::CustomDashboardService.name_for_path(new_dashboard_path),
          default: false,
          system_dashboard: false
        }
      end

      def push_authorized?
        Gitlab::UserAccess.new(current_user, container: project).can_push_to_branch?(branch)
      end

      def dashboard_template
        @dashboard_template ||= params[:dashboard]
      end

      def branch
        @branch ||= params[:branch]
      end

      def new_or_default_branch?
        !repository.branch_exists?(params[:branch]) || project.default_branch == params[:branch]
      end

      def valid_branch_name?
        Gitlab::GitRefValidator.validate(params[:branch])
      end

      def new_dashboard_path
        @new_dashboard_path ||= File.join(USER_DASHBOARDS_DIR, file_name)
      end

      def file_name
        @file_name ||= File.basename(params[:file_name])
      end

      def target_file_type_valid?
        File.extname(params[:file_name]) == ALLOWED_FILE_TYPE
      end

      def wrap_error(result)
        if result[:message] == 'A file with this name already exists'
          error(_("A file with '%{file_name}' already exists in %{branch} branch") % { file_name: file_name, branch: branch }, :bad_request)
        else
          result
        end
      end

      def new_dashboard_content
        ::Gitlab::Metrics::Dashboard::Processor
          .new(project, raw_dashboard, sequence, {})
          .process.deep_stringify_keys.to_yaml
      end

      def repository
        @repository ||= project.repository
      end

      def raw_dashboard
        dashboard_service.new(project, current_user, dashboard_service_options).raw_dashboard
      end

      def dashboard_service_options
        {
          embedded: false,
          dashboard_path: dashboard_template
        }
      end

      def sequence
        SEQUENCES[dashboard_template] || []
      end
    end
  end
end
