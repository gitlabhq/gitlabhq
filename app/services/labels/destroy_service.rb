module Labels
  class DestroyService < Labels::BaseService
    def execute(label)
      Label.transaction do
        label.destroy

        return if label.project_label?

        destroy_global_label(label.label_type, label.title) if label.global_label?
        destroy_group_label(label.label_type, label.title) if label.group_label?
      end
    end

    private

    def destroy_global_label(label_type, title)
      if subject.nil?
        destroy_labels(Group.all, label_type, title)
        destroy_labels(Project.all, label_type, title)
      end

      if subject.is_a?(Group)
        destroy_labels(nil, label_type, title)
        destroy_labels(Group.where.not(id: subject), label_type, title)
        destroy_labels(Project.all, label_type, title)
      end

      if subject.is_a?(Project)
        destroy_labels(nil, label_type, title)
        destroy_labels(Group.all, label_type, title)
        destroy_labels(Project.where.not(id: subject), label_type, title)
      end
    end

    def destroy_group_label(label_type, title)
      if subject.is_a?(Group)
        destroy_labels(subject.projects, label_type, title)
      end

      if subject.is_a?(Project)
        destroy_labels(subject.group, label_type, title)
        destroy_labels(subject.group.projects.where.not(id: subject), label_type, title)
      end
    end

    def destroy_labels(subject, label_type, title)
      find_labels(subject, label_type, title).each(&:destroy)
    end
  end
end
