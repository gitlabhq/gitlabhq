# frozen_string_literal: true

module Ml
  class CreateModelVersionService
    def initialize(model, params = {})
      @model = model
      @version = params[:version]
      @package = params[:package]
      @description = params[:description]
      @user = params[:user]
      @metadata = params[:metadata]
      @candidate_id = params[:candidate_id]
    end

    def execute
      ApplicationRecord.transaction do
        @version ||= Ml::IncrementVersionService.new(@model.latest_version.try(:version)).execute

        error(_("Version must be semantic version")) unless Packages::SemVer.match(@version)

        @model_version = Ml::ModelVersion.new(model: @model, project: @model.project, version: @version,
          description: @description)

        @model_version.save

        error(@model_version.errors.full_messages) unless @model_version.persisted?

        package = find_or_create_candidate
        package ||= find_or_create_package(@model.name, @version)
        error(_("Can't create model version package")) unless package

        @model_version.update! package: package

        @model_version.add_metadata(@metadata)

        Gitlab::InternalEvents.track_event(
          'model_registry_ml_model_version_created',
          project: @model.project,
          user: @user
        )

        audit_creation_event

        ServiceResponse.success(message: [], payload: { model_version: @model_version })
      end
    rescue ActiveRecord::RecordInvalid => e
      ServiceResponse.error(message: [e.message], payload: { model_version: nil })
    rescue ModelVersionCreationError => e
      ServiceResponse.error(message: e.errors, payload: { model_version: nil })
    end

    private

    def find_or_create_candidate
      if @candidate_id
        candidate = ::Ml::Candidate.with_project_id_and_id(@model.project_id, @candidate_id.model_id)
        error(_("Run not found")) unless candidate
        error(_("Run has already a model version")) if candidate.model_version_id
        error(_("Run's experiment does not belong to this model")) unless candidate.experiment.model_id == @model.id

        candidate.update! model_version: @model_version

        package = candidate.package
        package.update!(name: @model_version.name, version: @model_version.version) if package
      else
        candidate = ::Ml::CreateCandidateService.new(
          @model.default_experiment,
          { model_version: @model_version }
        ).execute
        error(_("Version must be semantic version")) unless candidate

        package = @package
      end

      package
    end

    def find_or_create_package(model_name, model_version)
      package_params = {
        name: model_name,
        version: model_version
      }

      ::Packages::MlModel::FindOrCreatePackageService
        .new(@model.project, @user, package_params)
        .execute
    end

    def error(errors)
      raise ModelVersionCreationError.new(Array.wrap(errors)) # rubocop:disable Style/RaiseArgs -- This is a custom error and is handled in this class
    end

    class ModelVersionCreationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end
    end

    def audit_creation_event
      audit_context = {
        name: 'ml_model_version_created',
        author: @user,
        scope: @model.project,
        target: @model_version,
        message: "MlModelVersion #{@model_version.name}/#{@model_version.version} created"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
