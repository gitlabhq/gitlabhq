module Labels
  class UpdateService
    def initialize(subject, user, params = {})
      @subject, @user, @params = subject, user, params.dup
    end

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

    private

    attr_reader :subject, :user, :params
  end
end
