module Labels
  class CreateService < Labels::BaseService
    def execute
      Label.transaction do
        label = subject.labels.build(params)
        label.label_type = subject.is_a?(Group) ? :group_label : :project_label

        return label if subject.is_a?(Project) && exists_at_group_level?

        if label.save && subject.is_a?(Group)
          replicate_labels_to_projects
        end

        label
      end
    end

    private

    def exists_at_group_level?
      subject.group && subject.group.labels.where(title: params[:title]).exists?
    end

    def replicate_labels_to_projects
      subject.projects.each do |project|
        project.labels.find_or_create_by!(title: params[:title]) do |label|
          label.color = params[:color]
          label.description = params[:description]
          label.label_type = :group_label
        end
      end
    end
  end
end
