module EE
  module UsersController
    def available_templates
      render json: load_custom_project_templates
    end

    private

    def load_custom_project_templates
      @custom_project_templates ||= user.available_custom_project_templates(search: params[:search]).page(params[:page])
    end
  end
end
