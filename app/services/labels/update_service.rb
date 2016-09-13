module Labels
  class UpdateService < Labels::BaseService
    def execute(label)
      Label.transaction do
        previous_title = label.title.dup
        label.update(params)

        return label unless label.valid? && label.group_label?

        if subject.is_a?(Group)
          update_labels(subject.projects, previous_title)
        end

        if subject.is_a?(Project)
          update_labels(subject.group, previous_title)
          update_labels(subject.group.projects - [subject], previous_title)
        end

        label
      end
    end

    private

    def update_labels(subject, title)
      Label.with_type(:group_label)
           .where(subject: subject, title: title)
           .update_all(params)
    end
  end
end
