# frozen_string_literal: true

module Projects
  class AutocompleteService < BaseService
    include LabelsAsHash
    def issues
      IssuesFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def milestones
      finder_params = {
        project_ids: [@project.id],
        state: :active,
        order: { due_date: :asc, title: :asc }
      }

      finder_params[:group_ids] = @project.group.self_and_ancestors.select(:id) if @project.group

      MilestonesFinder.new(finder_params).execute.select([:iid, :title, :due_date])
    end

    def merge_requests
      MergeRequestsFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def commands(noteable, type)
      return [] unless noteable

      QuickActions::InterpretService.new(project, current_user).available_commands(noteable)
    end

    def snippets
      SnippetsFinder.new(current_user, project: project).execute.select([:id, :title])
    end

    def labels_as_hash(target)
      super(target, project_id: project.id, include_ancestor_groups: true)
    end
  end
end

Projects::AutocompleteService.prepend_mod_with('Projects::AutocompleteService')
