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
      SlashCommands::InterpretService.command_definitions
    end
  end
end
