module Labels
  class UpdateService < Labels::BaseService
    def execute(label)
      previous_title = label.title.dup

      Label.transaction do
        label.update(params)

        return label unless label.valid?

        replicate_global_label(label.label_type, previous_title) if label.global_label?
        replicate_group_label(label.label_type, previous_title) if label.group_label?

        label
      end
    end

    private

    def replicate_global_label(label_type, title)
      if subject.nil?
        replicate_label(Group.all, label_type, title)
        replicate_label(Project.all, label_type, title)
      end

      if subject.is_a?(Group)
        replicate_label(nil, label_type, title)
        replicate_label(Group.where.not(id: subject), label_type, title)
        replicate_label(Project.all, label_type, title)
      end

      if subject.is_a?(Project)
        replicate_label(nil, label_type, title)
        replicate_label(Group.all, label_type, title)
        replicate_label(Project.where.not(id: subject), label_type, title)
      end
    end

    def replicate_group_label(label_type, title)
      if subject.is_a?(Group)
        replicate_label(subject.projects, label_type, title)
      end

      if subject.is_a?(Project)
        replicate_label(subject.group, label_type, title)
        replicate_label(subject.group.projects.where.not(id: subject), label_type, title)
      end
    end

    def replicate_label(subject, label_type, title)
      find_labels(subject, label_type, title).update_all(params)
    end
  end
end
