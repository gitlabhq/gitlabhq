module Groups
  class AutocompleteService < Groups::BaseService
    include LabelsAsHash
    def epics
      # TODO: change to EpicsFinder once frontend supports epics from external groups.
      # See https://gitlab.com/gitlab-org/gitlab-ee/issues/6837
      DeclarativePolicy.user_scope do
        if Ability.allowed?(current_user, :read_epic, group)
          group.epics
        else
          []
        end
      end
    end

    def labels_as_hash(target)
      super(target, group_id: group.id, only_group_labels: true)
    end

    def commands(noteable)
      return [] unless noteable

      QuickActions::InterpretService.new(nil, current_user).available_commands(noteable)
    end
  end
end
