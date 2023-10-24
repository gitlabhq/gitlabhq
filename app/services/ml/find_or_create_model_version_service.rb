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
      model = Ml::FindOrCreateModelService.new(project, name).execute
      Ml::ModelVersion.find_or_create!(model, version, package, description)
    end

    private

    attr_reader :version, :name, :project, :package, :description
  end
end
