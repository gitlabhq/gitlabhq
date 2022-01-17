# frozen_string_literal: true

module WorkItemsHierarchy
  extend ActiveSupport::Concern

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def planning_hierarchy
    return render_404 unless Feature.enabled?(:work_items_hierarchy, @project, default_enabled: :yaml)

    render 'shared/planning_hierarchy'
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end

WorkItemsHierarchy.prepend_mod_with('WorkItemsHierarchy')
