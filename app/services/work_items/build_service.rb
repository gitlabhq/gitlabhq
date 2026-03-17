# frozen_string_literal: true

module WorkItems
  class BuildService < ::Issues::BuildService
    def related_issue
      related_issue = project.work_items.find_by_iid(params[:add_related_issue])
      related_issue if Ability.allowed?(current_user, :read_issue, related_issue)
    end

    private

    def model_klass
      ::WorkItem
    end
  end
end
