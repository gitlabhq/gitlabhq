module Labels
  class ReplicateService < Labels::BaseService
    def execute
      global_labels.each { |label| replicate_label(label, :global_label) }
      group_labels.each  { |label| replicate_label(label, :group_label) }
    end

    private

    def global_labels
      Label.templates
    end

    def group_labels
      subject.group.present? ? subject.group.labels : []
    end

    def replicate_label(label, label_type)
      subject.labels.find_or_create_by!(title: label.title) do |replicated|
        replicated.color       = label.color
        replicated.description = label.description
        replicated.label_type  = label_type
      end
    end
  end
end
