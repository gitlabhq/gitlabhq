module Labels
  class UpdateService < Labels::BaseService
    def execute(label)
      Label.transaction do
        if subject.is_a?(Group)
          subject.projects.each do |project|
            project_label = project.labels.find_by(title: label.title)
            project_label.update_attributes(params) if project_label.present?
          end
        end

        label.update_attributes(params)
      end
    end
  end
end
