module Labels
  class DestroyService < Labels::BaseService
    def execute(label)
      Label.transaction do
        label.destroy

        return unless label.group_label?

        if subject.is_a?(Group)
          destroy_labels(subject.projects, label.title)
        end

        if subject.is_a?(Project)
          destroy_labels(subject.group, label.title)
          destroy_labels(subject.group.projects - [subject], label.title)
        end
      end
    end

    private

    def destroy_labels(subject, title)
      find_labels(subject, title).each(&:destroy)
    end
  end
end
