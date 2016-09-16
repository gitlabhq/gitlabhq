module Labels
  class ToggleSubscriptionService < Labels::BaseService
    def execute(label)
      Label.transaction do
        label.toggle_subscription(user)

        return if label.project_label?

        replicate_global_label(label.label_type, label.title, &toggle_subscription) if label.global_label?
        replicate_group_label(label.label_type, label.title, &toggle_subscription) if label.group_label?
      end
    end

    private

    def toggle_subscription
      Proc.new do |labels|
        labels.each { |label| label.toggle_subscription(user) }
      end
    end
  end
end
