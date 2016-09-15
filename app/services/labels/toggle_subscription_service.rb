module Labels
  class ToggleSubscriptionService < Labels::BaseService
    def execute(label)
      Label.transaction do
        label.toggle_subscription(user)

        return unless label.group_label?

        if subject.is_a?(Group)
          toggle_subscription(subject.projects, label.title)
        end

        if subject.is_a?(Project)
          toggle_subscription(subject.group, label.title)
          toggle_subscription(subject.group.projects - [subject], label.title)
        end
      end
    end

    private

    def toggle_subscription(subject, title)
      find_labels(subject, title).each { |label| label.toggle_subscription(user) }
    end
  end
end
