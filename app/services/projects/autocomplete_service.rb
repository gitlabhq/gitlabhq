module Projects
  class AutocompleteService < BaseService
    def issues
      @project.issues.visible_to_user(current_user).opened.select([:iid, :title])
    end

    def milestones
      @project.milestones.active.reorder(due_date: :asc, title: :asc).select([:iid, :title])
    end

    def merge_requests
      @project.merge_requests.opened.select([:iid, :title])
    end

    def labels
      @project.labels.select([:title, :color])
    end

    def commands
      # We don't return commands when editing an issue or merge request
      # This should be improved by not enabling autocomplete at the JS-level
      # following this suggestion: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5021#note_13837384
      return [] if !target || %w[edit update].include?(params[:action_name])

      SlashCommands::InterpretService.command_definitions(
        project: project,
        noteable: target,
        current_user: current_user
      )
    end

    private

    def target
      @target ||= begin
        noteable_id = params[:type_id]
        case params[:type]
        when 'Issue'
          IssuesFinder.new(current_user, project_id: project.id, state: 'all').
            execute.find_or_initialize_by(iid: noteable_id)
        when 'MergeRequest'
          MergeRequestsFinder.new(current_user, project_id: project.id, state: 'all').
            execute.find_or_initialize_by(iid: noteable_id)
        else
          nil
        end
      end
    end
  end
end
