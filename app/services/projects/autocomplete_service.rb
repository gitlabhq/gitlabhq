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

    def commands(noteable_type, noteable_id)
      SlashCommands::InterpretService.command_definitions(
        project: @project,
        noteable: command_target(noteable_type, noteable_id),
        current_user: current_user
      )
    end

    private

    def command_target(noteable_type, noteable_id)
      case noteable_type
      when 'Issue'
        IssuesFinder.new(current_user, project_id: @project.id, state: 'all').
          execute.find_or_initialize_by(iid: noteable_id)
      when 'MergeRequest'
        MergeRequestsFinder.new(current_user, project_id: @project.id, state: 'all').
          execute.find_or_initialize_by(iid: noteable_id)
      else
        nil
      end
    end
  end
end
