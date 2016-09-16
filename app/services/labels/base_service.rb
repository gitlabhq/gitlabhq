module Labels
  class BaseService
    def initialize(subject, user, params = {})
      @subject, @user, @params = subject, user, params.dup
    end

    private

    attr_reader :subject, :user, :params

    def replicate_global_label(label_type, title, &block)
      if subject.nil?
        block.call(find_labels(Group.all, label_type, title))
        block.call(find_labels(Project.all, label_type, title))
      end

      if subject.is_a?(Group)
        block.call(find_labels(nil, label_type, title))
        block.call(find_labels(Group.where.not(id: subject), label_type, title))
        block.call(find_labels(Project.all, label_type, title))
      end

      if subject.is_a?(Project)
        block.call(find_labels(nil, label_type, title))
        block.call(find_labels(Group.all, label_type, title))
        block.call(find_labels(Project.where.not(id: subject), label_type, title))
      end
    end

    def replicate_group_label(label_type, title, &block)
      if subject.is_a?(Group)
        block.call(find_labels(subject.projects, label_type, title))
      end

      if subject.is_a?(Project)
        block.call(find_labels(subject.group, label_type, title))
        block.call(find_labels(subject.group.projects.where.not(id: subject), label_type, title))
      end
    end

    def find_labels(subject, label_type, title)
      Label.with_type(label_type).where(subject: subject, title: title)
    end
  end
end
