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

        package = @package || find_or_create_package(@model.name, @version)

        model_version = Ml::ModelVersion.create!(model: @model, project: @model.project, version: @version,
          package: package, description: @description)

        model_version.candidate = ::Ml::CreateCandidateService.new(
          @model.default_experiment,
          { model_version: model_version }
        ).execute

        model_version.add_metadata(@metadata)

        Gitlab::InternalEvents.track_event(
          'model_registry_ml_model_version_created',
          project: @model.project,
          user: @user
        )

        model_version
      end
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
  end
end
