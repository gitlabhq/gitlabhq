# frozen_string_literal: true

module Ml
  class FindOrCreateModelVersionService
    def initialize(project, params = {})
      @project = project
      @name = params[:model_name]
      @version = params[:version]
      @package = params[:package]
      @description = params[:description]
    end

    def execute
      model = Ml::FindOrCreateModelService.new(@project, @name).execute

      model_version = Ml::ModelVersion.find_or_create!(model, @version, @package, @description)

      unless model_version.candidate
        model_version.candidate = ::Ml::CreateCandidateService.new(
          model.default_experiment,
          { model_version: model_version }
        ).execute
      end

      model_version
    end
  end
end
