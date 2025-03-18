# frozen_string_literal: true

module Preloaders
  class IssuablesPreloader
    attr_reader :projects, :current_user, :associations

    def initialize(nodes, current_user, associations)
      @projects = nodes.map(&:project)
      @current_user = current_user
      @associations = associations
    end

    def preload_all
      ::Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects, current_user).execute
      ::Preloaders::GroupPolicyPreloader.new(projects.filter_map(&:group), current_user).execute
      ActiveRecord::Associations::Preloader.new(records: projects, associations: associations).call
    end
  end
end

Preloaders::IssuablesPreloader.prepend_mod
