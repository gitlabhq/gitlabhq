module Projects
  class AutocompleteService < BaseService
    def issues
      IssuesFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def milestones
      finder_params = {
        project_ids: [@project.id],
        state: :active,
        order: { due_date: :asc, title: :asc }
      }

      finder_params[:group_ids] = [@project.group.id] if @project.group

      MilestonesFinder.new(finder_params).execute.select([:iid, :title])
    end

    def merge_requests
      MergeRequestsFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def labels
      LabelsFinder.new(current_user, project_id: project.id).execute.select([:title, :color])
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
        issuable: noteable,
        current_user: current_user
      }
      QuickActions::InterpretService.command_definitions.map do |definition|
        next unless definition.available?(opts)

        definition.to_h(opts)
      end.compact
    end
  end
end
