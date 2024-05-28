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
    end

    def execute
      ApplicationRecord.transaction do
        @version ||= Ml::IncrementVersionService.new(@model.latest_version.try(:version)).execute

        error(_("Version must be semantic version")) unless Packages::SemVer.match(@version)

        package = @package || find_or_create_package(@model.name, @version)

        error(_("Can't create model version package")) unless package

        @model_version = Ml::ModelVersion.new(model: @model, project: @model.project, version: @version,
          package: package, description: @description)

        @model_version.save

        error(@model_version.errors.full_messages) unless @model_version.persisted?

        @model_version.candidate = ::Ml::CreateCandidateService.new(
          @model.default_experiment,
          { model_version: @model_version }
        ).execute

        error(_("Version must be semantic version")) unless @model_version.candidate

        @model_version.add_metadata(@metadata)

        Gitlab::InternalEvents.track_event(
          'model_registry_ml_model_version_created',
          project: @model.project,
          user: @user
        )

        ServiceResponse.success(message: [], payload: { model_version: @model_version })
      end
    rescue ActiveRecord::RecordInvalid => e
      ServiceResponse.error(message: [e.message], payload: { model_version: nil })
    rescue ModelVersionCreationError => e
      ServiceResponse.error(message: e.errors, payload: { model_version: nil })
    end

    private

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
  end
end
