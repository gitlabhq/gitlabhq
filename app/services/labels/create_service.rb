module Labels
  class CreateService
    def initialize(current_user, project, params = {})
      @current_user = current_user
      @group = project.group
      @project = project
      @params = params.dup
    end

    def execute
      find_or_create_label
    end

    private

    attr_reader :current_user, :group, :project, :params

    def available_labels
      @available_labels ||= LabelsFinder.new(current_user, project_id: project.id).execute
    end

    def find_or_create_label
      new_label = available_labels.find_by(title: title)
      new_label ||= project.labels.create(params)

      new_label
    end

    def title
      params[:title] || params[:name]
    end
  end
end
