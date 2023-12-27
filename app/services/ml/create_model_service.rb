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
        model = Ml::Model.new(
          project: @project,
          name: @name,
          user: @user,
          description: @description,
          default_experiment: default_experiment
        )

        model.save

        if model.persisted?
          add_metadata(model, @metadata)

          Gitlab::InternalEvents.track_event(
            'model_registry_ml_model_created',
            project: @project,
            user: @user
          )
        end

        model
      end
    end

    private

    def default_experiment
      @default_experiment ||= Ml::FindOrCreateExperimentService.new(@project, @name).execute
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
  end
end
