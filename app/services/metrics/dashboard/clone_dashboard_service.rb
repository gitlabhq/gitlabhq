# frozen_string_literal: true

# Copies system dashboard definition in .yml file into designated
# .yml file inside `.gitlab/dashboards`
module Metrics
  module Dashboard
    class CloneDashboardService < ::BaseService
      ALLOWED_FILE_TYPE = '.yml'
      USER_DASHBOARDS_DIR = ::Metrics::Dashboard::ProjectDashboardService::DASHBOARD_ROOT

      class << self
        def allowed_dashboard_templates
          @allowed_dashboard_templates ||= Set[::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH].freeze
        end

        def sequences
          @sequences ||= {
            ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => [::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
                                                                             ::Gitlab::Metrics::Dashboard::Stages::ProjectMetricsInserter,
                                                                             ::Gitlab::Metrics::Dashboard::Stages::Sorter].freeze
          }.freeze
        end
      end

      def execute
        catch(:error) do
          throw(:error, error(_(%q(You can't commit to this project)), :forbidden)) unless push_authorized?

          result = ::Files::CreateService.new(project, current_user, dashboard_attrs).execute
          throw(:error, wrap_error(result)) unless result[:status] == :success

          repository.refresh_method_caches([:metrics_dashboard])
          success(result.merge(http_status: :created, dashboard: dashboard_details))
        end
      end

      private

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
          display_name: ::Metrics::Dashboard::ProjectDashboardService.name_for_path(new_dashboard_path),
          default: false,
          system_dashboard: false
        }
      end

      def push_authorized?
        Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(branch)
      end

      def dashboard_template
        @dashboard_template ||= begin
          throw(:error, error(_('Not found.'), :not_found)) unless self.class.allowed_dashboard_templates.include?(params[:dashboard])

          params[:dashboard]
        end
      end

      def branch
        @branch ||= begin
          throw(:error, error(_('There was an error creating the dashboard, branch name is invalid.'), :bad_request)) unless valid_branch_name?
          throw(:error, error(_('There was an error creating the dashboard, branch named: %{branch} already exists.') % { branch: params[:branch] }, :bad_request)) unless new_or_default_branch? # temporary validation for first UI iteration

          params[:branch]
        end
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
        @file_name ||= begin
          throw(:error, error(_('The file name should have a .yml extension'), :bad_request)) unless target_file_type_valid?

          File.basename(params[:file_name])
        end
      end

      def target_file_type_valid?
        File.extname(params[:file_name]) == ALLOWED_FILE_TYPE
      end

      def new_dashboard_content
        ::Gitlab::Metrics::Dashboard::Processor
          .new(project, raw_dashboard, sequence, {})
          .process.deep_stringify_keys.to_yaml
      end

      def repository
        @repository ||= project.repository
      end

      def wrap_error(result)
        if result[:message] == 'A file with this name already exists'
          error(_("A file with '%{file_name}' already exists in %{branch} branch") % { file_name: file_name, branch: branch }, :bad_request)
        else
          result
        end
      end

      def raw_dashboard
        YAML.safe_load(File.read(Rails.root.join(dashboard_template)))
      end

      def sequence
        self.class.sequences[dashboard_template]
      end
    end
  end
end

Metrics::Dashboard::CloneDashboardService.prepend_if_ee('EE::Metrics::Dashboard::CloneDashboardService')
