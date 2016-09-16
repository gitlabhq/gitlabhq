module Labels
  class ReplicateService < Labels::BaseService
    def execute
      replicate_global_labels
      replicate_group_labels unless subject.is_a?(Group)
    end

    private

    def global_labels
      Label.global_labels
    end

    def group_labels
      subject.group.present? ? subject.group.labels : []
    end

    def replicate_global_labels
      global_labels.each { |label| replicate_label(label, :global_label) }
    end

    def replicate_group_labels
      group_labels.each  { |label| replicate_label(label, :group_label) }
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
