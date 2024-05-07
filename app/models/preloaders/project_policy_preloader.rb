# frozen_string_literal: true

module Preloaders
  class ProjectPolicyPreloader
    def initialize(projects, current_user)
      @projects = projects
      @current_user = current_user
    end

    def execute
      return if projects.is_a?(ActiveRecord::NullRelation)

      ActiveRecord::Associations::Preloader.new(
        records: projects,
        associations: { creator: [], group: :route, namespace: :owner }
      ).call
      ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
    end

    private

    attr_reader :projects, :current_user
  end
end

Preloaders::ProjectPolicyPreloader.prepend_mod
