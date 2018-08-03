# frozen_string_literal: true

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

      finder_params[:group_ids] = @project.group.self_and_ancestors_ids if @project.group

      MilestonesFinder.new(finder_params).execute.select([:iid, :title])
    end

    def merge_requests
      MergeRequestsFinder.new(current_user, project_id: project.id, state: 'opened').execute.select([:iid, :title])
    end

    def labels_as_hash(target = nil)
      available_labels = LabelsFinder.new(
        current_user,
        project_id: project.id,
        include_ancestor_groups: true
      ).execute

      label_hashes = available_labels.as_json(only: [:title, :color])

      if target&.respond_to?(:labels)
        already_set_labels = available_labels & target.labels
        if already_set_labels.present?
          titles = already_set_labels.map(&:title)
          label_hashes.each do |hash|
            if titles.include?(hash['title'])
              hash[:set] = true
            end
          end
        end
      end

      label_hashes
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
