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

    def labels(target = nil)
      labels = LabelsFinder.new(current_user, project_id: project.id).execute.select([:color, :title])

      return labels unless target&.respond_to?(:labels)

      issuable_label_titles = target.labels.pluck(:title)

      if issuable_label_titles
        labels = labels.as_json(only: [:title, :color])

        issuable_label_titles.each do |issuable_label_title|
          found_label = labels.find { |label| label['title'] == issuable_label_title }
          found_label[:set] = true if found_label
        end
      end

      labels
    end

    def commands(noteable, type)
      noteable ||=
        case type
        when 'Issue'
          @project.issues.build
        when 'MergeRequest'
          @project.merge_requests.build
        end

      return [] unless noteable&.is_a?(Issuable)

      QuickActions::InterpretService.new(project, current_user).available_commands(noteable)
    end
  end
end
