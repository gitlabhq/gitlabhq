# frozen_string_literal: true

module Ml
  module ExperimentTracking
    class ExperimentRepository
      attr_accessor :project, :user

      def initialize(project, user = nil)
        @project = project
        @user = user
      end

      def by_iid_or_name(iid: nil, name: nil)
        return ::Ml::Experiment.by_project_id_and_iid(project.id, iid) if iid

        ::Ml::Experiment.by_project_id_and_name(project.id, name) if name
      end

      def all
        Projects::Ml::ExperimentFinder.new(@project).execute
      end

      def create!(name, tags = nil)
        experiment = ::Ml::Experiment.create!(name: name,
          user: user,
          project: project)

        add_tags(experiment, tags)

        experiment
      end

      def add_tag!(experiment, key, value)
        return unless experiment.present?

        experiment.metadata.create!(name: key, value: value)
      end

      private

      def timestamps
        current_time = Time.zone.now

        { created_at: current_time, updated_at: current_time }
      end

      def add_tags(experiment, tag_definitions)
        return unless experiment.present? && tag_definitions.present?

        entities = tag_definitions.map do |d|
          {
            experiment_id: experiment.id,
            name: d[:key],
            value: d[:value],
            **timestamps
          }
        end

        ::Ml::ExperimentMetadata.insert_all(entities, returning: false) unless entities.empty?
      end
    end
  end
end
