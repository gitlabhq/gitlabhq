module Labels
  class ReplicateService < Labels::BaseService
    def execute
      labels.each { |label| replicate(label) }
    end

    private

    def labels
      global_labels = Label.templates
      group_labels  = subject.group.present? ? subject.group.labels : []

      global_labels + group_labels
    end

    def replicate(label)
      subject.labels.find_or_create_by!(title: label.title) do |replicated|
        replicated.color = label.color
        replicated.description = label.description
      end
    end
  end
end
