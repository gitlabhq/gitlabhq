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

    # Only creates the label if current_user can do so, if the label does not exist
    # and the user can not create the label, nil is returned
    def find_or_create_label
      new_label = available_labels.find_by(title: title)

      if new_label.nil? && (skip_authorization || Ability.allowed?(current_user, :admin_label, project))
        new_label = project.labels.create(params)
      end

      new_label
    end

    def title
      params[:title] || params[:name]
    end
  end
end
