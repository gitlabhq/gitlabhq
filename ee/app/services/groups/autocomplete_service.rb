module Groups
  class AutocompleteService < Groups::BaseService
    def labels_as_hash(target = nil)
      available_labels = LabelsFinder.new(
        current_user,
        group_id: group.id,
        include_ancestor_groups: true,
        only_group_labels: true
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
  end
end
