module Groups
  class AutocompleteService < Groups::BaseService
    def labels_as_hash(target = nil)
      available_labels = LabelsFinder.new(
        current_user,
        group_id: group.id,
        include_ancestor_groups: true,
        only_group_labels: true
      ).execute

      hashes = available_labels.as_json(only: [:title, :color])

      if target&.respond_to?(:labels)
        if already_set_labels = available_labels & target.labels
          titles = already_set_labels.map(&:title)
          hashes.each do |hash|
            if titles.include?(hash['title'])
              hash[:set] = true
            end
          end
        end
      end

      hashes
    end

    def epics
      EpicsFinder.new(current_user, group_id: group.id).execute
    end
  end
end
