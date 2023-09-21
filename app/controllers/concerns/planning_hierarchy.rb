# frozen_string_literal: true

module PlanningHierarchy
  extend ActiveSupport::Concern

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def planning_hierarchy
    return access_denied! unless can?(current_user, :read_planning_hierarchy, @project)

    route_not_found
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end

PlanningHierarchy.prepend_mod_with('PlanningHierarchy')
