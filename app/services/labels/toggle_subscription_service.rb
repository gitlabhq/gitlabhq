module Labels
  class ToggleSubscriptionService < Labels::BaseService
    def execute(label)
      Label.transaction do
        label.toggle_subscription(user)

        return if label.project_label?

        toggle_subscription_to_global_label(label.label_type, label.title) if label.global_label?
        toggle_subscription_to_group_label(label.label_type, label.title) if label.group_label?
      end
    end

    private

    def toggle_subscription_to_global_label(label_type, title)
      if subject.nil?
        toggle_subscription(Group.all, label_type, title)
        toggle_subscription(Project.all, label_type, title)
      end

      if subject.is_a?(Group)
        toggle_subscription(nil, label_type, title)
        toggle_subscription(Group.where.not(id: subject), label_type, title)
        toggle_subscription(Project.all, label_type, title)
      end

      if subject.is_a?(Project)
        toggle_subscription(nil, label_type, title)
        toggle_subscription(Group.all, label_type, title)
        toggle_subscription(Project.where.not(id: subject), label_type, title)
      end
    end

    def toggle_subscription_to_group_label(label_type, title)
      if subject.is_a?(Group)
        toggle_subscription(subject.projects, label_type, title)
      end

      if subject.is_a?(Project)
        toggle_subscription(subject.group, label_type, title)
        toggle_subscription(subject.group.projects.where.not(id: subject), label_type, title)
      end
    end

    def toggle_subscription(subject, label_type, title)
      find_labels(subject, label_type, title).each { |label| label.toggle_subscription(user) }
    end
  end
end
