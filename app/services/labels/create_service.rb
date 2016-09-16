module Labels
  class CreateService < Labels::BaseService
    def execute
      label = Label.new(params.merge(subject: subject))

      return label if label_already_exists?(label)

      Label.transaction do
        if label.save
          replicate_global_label if label.global_label?
          replicate_group_label if label.group_label?
        end
      end

      label
    end

    private

    def label_already_exists?(label)
      return false if label.global_label?
      return label_exists_at_global_level? if label.group_label?

      label_exists_at_global_level? || label_exists_at_group_level?
    end

    def label_exists_at_global_level?
      find_labels(nil, :global_label, params[:title]).exists?
    end

    def label_exists_at_group_level?
      return false unless subject.group.present?

      find_labels(subject.group, :group_label, params[:title]).exists?
    end

    def replicate_global_label
      replicate_label_to_groups(Group.all)
      replicate_label_to_projects(Project.all)
    end

    def replicate_group_label
      replicate_label_to_projects(subject.projects)
    end

    def replicate_label_to_groups(groups)
      groups.each { |group| replicate_label_to_resource(group) }
    end

    def replicate_label_to_projects(projects)
      projects.each { |project| replicate_label_to_resource(project) }
    end

    def replicate_label_to_resource(resource)
      resource.labels.find_or_create_by!(title: params[:title]) do |label|
        label.color = params[:color]
        label.description = params[:description]
        label.label_type = params[:label_type]
      end
    end
  end
end
