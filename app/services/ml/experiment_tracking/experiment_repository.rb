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
        ::Ml::Experiment.by_project_id(project.id)
      end

      def create!(name)
        ::Ml::Experiment.create!(name: name,
                                 user: user,
                                 project: project)
      end
    end
  end
end
