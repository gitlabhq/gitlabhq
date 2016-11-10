module Labels
  class FindOrCreateService
    def initialize(current_user, project, params = {})
      @current_user = current_user
      @project = project
      @params = params.dup
    end

    def execute(skip_authorization: false)
      @skip_authorization = skip_authorization
      find_or_create_label
    end

    private

    attr_reader :current_user, :project, :params, :skip_authorization

    def available_labels
      @available_labels ||= LabelsFinder.new(
        current_user,
        project_id: project.id
      ).execute(skip_authorization: skip_authorization)
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
