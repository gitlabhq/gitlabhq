# frozen_string_literal: true

module Ml
  class CreateCandidateService
    def initialize(experiment, params = {})
      @experiment = experiment
      @name = params[:name]
      @user = params[:user]
      @start_time = params[:start_time]
      @model_version = params[:model_version]
    end

    def execute
      Ml::Candidate.create!(
        experiment: experiment,
        project: experiment.project,
        name: candidate_name,
        start_time: start_time || 0,
        user: user,
        model_version: model_version
      )
    end

    private

    def candidate_name
      name.presence || random_candidate_name
    end

    def random_candidate_name
      parts = Array.new(3).map { FFaker::AnimalUS.common_name.downcase.delete(' ') } << rand(10000)
      parts.join('-').truncate(255)
    end

    attr_reader :name, :user, :experiment, :start_time, :model_version
  end
end
