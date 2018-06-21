module Groups
  class AutocompleteService < Groups::BaseService
    def labels(target = nil)
      labels = LabelsFinder.new(
        current_user,
        group_id: group.id,
        include_ancestor_groups: true,
        only_group_labels: true
      ).execute.select([:color, :title])

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

    def epics
      EpicsFinder.new(current_user, group_id: group.id).execute
    end
  end
end
