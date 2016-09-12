module Labels
  class ReplicateService
    def initialize(subject, user)
      @subject, @user = subject, user
    end

    def execute
      labels.each { |label| replicate(label) }
    end

    private

    attr_reader :subject, :user

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
