# frozen_string_literal: true

module Ml
  class CreateModelService
    def initialize(project, name, user = nil, description = nil, metadata = [])
      @project = project
      @name = name
      @description = description
      @metadata = metadata
      @user = user
    end

    def execute
      ApplicationRecord.transaction do
        experiment_result = Ml::CreateExperimentService.new(@project, experiment_name, @user).execute

        next experiment_result if experiment_result.error?

        model = Ml::Model.new(
          project: @project,
          name: @name,
          user: @user,
          description: @description,
          default_experiment: experiment_result.payload
        )

        model.save

        next error(model.errors.full_messages) unless model.persisted?

        Gitlab::InternalEvents.track_event(
          'model_registry_ml_model_created',
          project: @project,
          user: @user
        )

        add_metadata(model, @metadata)
        audit_creation_event(model)

        success(model)
      end
    end

    private

    def success(model)
      ServiceResponse.success(payload: model)
    end

    def error(reason)
      ServiceResponse.error(message: reason)
    end

    def add_metadata(model, metadata_key_value)
      return unless model.present? && metadata_key_value.present?

      entities = metadata_key_value.map do |d|
        {
          model_id: model.id,
          name: d[:key],
          value: d[:value]
        }
      end

      entities.each do |entry|
        ::Ml::ModelMetadata.create!(entry)
      end
    end

    def experiment_name
      Ml::Model.prefixed_experiment(@name)
    end

    def audit_creation_event(model)
      audit_context = {
        name: 'ml_model_created',
        author: @user,
        scope: @project,
        target: model,
        message: "MlModel #{model.name} created"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
