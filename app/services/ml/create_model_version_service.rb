# frozen_string_literal: true

module Ml
  class CreateModelVersionService
    def initialize(model, params = {})
      @model = model
      @version = params[:version]
      @package = params[:package]
      @description = params[:description]
    end

    def execute
      @version ||= Ml::IncrementVersionService.new(@model.latest_version.try(:version)).execute

      model_version = Ml::ModelVersion.find_or_create!(@model, @version, @package, @description)

      model_version.candidate = ::Ml::CreateCandidateService.new(
        @model.default_experiment,
        { model_version: model_version }
      ).execute

      model_version
    end
  end
end
