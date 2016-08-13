module Projects
  class AutocompleteService < BaseService
    def issues
      IssuesFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def milestones
      @project.milestones.active.reorder(due_date: :asc, title: :asc).select([:iid, :title])
    end

    def merge_requests
      MergeRequestsFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def labels
      @project.labels.select([:title, :color])
    end

    def commands(noteable, type)
      noteable ||=
        case type
        when 'Issue'
          @project.issues.build
        when 'MergeRequest'
          @project.merge_requests.build
        end

      return [] unless noteable && noteable.is_a?(Issuable)

      opts = {
        project: project,
        noteable: noteable,
        current_user: current_user
      }
      SlashCommands::InterpretService.command_definitions.map do |definition|
        next unless definition.available?(opts)

        definition.to_h(opts)
      end.compact
    end
  end
end
