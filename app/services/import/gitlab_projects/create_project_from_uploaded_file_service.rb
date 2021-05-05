# frozen_string_literal: true

module Import
  module GitlabProjects
    class CreateProjectFromUploadedFileService
      include ActiveModel::Validations
      include ::Services::ReturnServiceResponses

      validate :required_params_presence

      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params.dup
      end

      def execute
        return error(errors.full_messages.first) unless valid?
        return error(project.errors.full_messages&.first) unless project.saved?

        success(project)
      rescue StandardError => e
        error(e.message)
      end

      private

      attr_reader :current_user, :params

      def error(message)
        super(message, :bad_request)
      end

      def project
        @project ||= ::Projects::GitlabProjectsImportService.new(
          current_user,
          project_params,
          params[:override]
        ).execute
      end

      def project_params
        {
          name: params[:name],
          path: params[:path],
          namespace_id: params[:namespace].id,
          file: params[:file],
          overwrite: params[:overwrite],
          import_type: 'gitlab_project'
        }
      end

      def required_params
        [:path, :namespace, :file]
      end

      def required_params_presence
        required_params
          .select { |key| params[key].blank? }
          .each do |missing_parameter|
            errors.add(:base, "Parameter '#{missing_parameter}' is required")
          end
      end
    end
  end
end
