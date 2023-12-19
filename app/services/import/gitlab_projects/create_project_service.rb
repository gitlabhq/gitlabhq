# frozen_string_literal: true

# Creates a new project with an associated project export file to be imported
# The associated project export file might be associated with different strategies
# to acquire the file to be imported, the default file_acquisition_strategy
# is uploading a file (Import::GitlabProjects::FileAcquisitionStrategies::FileUpload)
module Import
  module GitlabProjects
    class CreateProjectService
      include ActiveModel::Validations
      include ::Services::ReturnServiceResponses

      validates_presence_of :path, :namespace

      # Creates a new CreateProjectService.
      #
      # @param [User] current_user
      # @param [Hash] :params
      # @param [Import::GitlabProjects::FileAcquisitionStrategies::*] :file_acquisition_strategy
      def initialize(current_user, params:, file_acquisition_strategy: FileAcquisitionStrategies::FileUpload)
        @current_user = current_user
        @params = params.dup
        @strategy = file_acquisition_strategy.new(current_user: current_user, params: params)
      end

      # Creates a project with the strategy parameters
      #
      # @return [Services::ServiceResponse]
      def execute
        return error(errors.full_messages) unless valid?
        return error(project.errors.full_messages) unless project.saved?

        success(project)
      rescue StandardError => e
        error(e.message)
      end

      # Cascade the validation to strategy
      def valid?
        super && strategy.valid?
      end

      # Merge with strategy's errors
      def errors
        super.tap { _1.merge!(strategy.errors) }
      end

      def read_attribute_for_validation(key)
        params[key]
      end

      private

      attr_reader :current_user, :params, :strategy

      def error(messages)
        messages = Array.wrap(messages)
        message = messages.shift
        super(message, :bad_request, pass_back: { other_errors: messages })
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
          overwrite: params[:overwrite],
          import_type: 'gitlab_project'
        }.merge(strategy.project_params)
      end
    end
  end
end
