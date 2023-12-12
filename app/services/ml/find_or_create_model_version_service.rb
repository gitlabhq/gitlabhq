# frozen_string_literal: true

module Ml
  class FindOrCreateModelVersionService
    def initialize(project, params = {})
      @project = project
      @name = params[:model_name]
      @version = params[:version]
      @package = params[:package]
      @description = params[:description]
      @user = params[:user]
      @params = params
    end

    def execute
      model_version = Ml::ModelVersion.by_project_id_name_and_version(@project.id, @name, @version)

      return model_version if model_version

      model = Ml::Model.by_project_id_and_name(@project.id, @name)

      return unless model

      Ml::CreateModelVersionService.new(model, @params).execute
    end
  end
end
