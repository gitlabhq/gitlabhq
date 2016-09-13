module Labels
  class DestroyService < Labels::BaseService
    def execute(label)
      Label.transaction do
        destroy_project_labels(label.title) if subject.is_a?(Group)
        label.destroy
      end
    end

    private

    def destroy_project_labels(title)
      subject.projects.each do |project|
        label = project.labels.find_by(title: title)
        label.destroy if label.present?
      end
    end
  end
end
