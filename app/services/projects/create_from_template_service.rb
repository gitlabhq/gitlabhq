module Projects
  class CreateFromTemplateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      template_name = params.delete(:template_name)
      file = Gitlab::ProjectTemplate.find(template_name).file

      params[:file] = file

      GitlabProjectsImportService.new(current_user, params).execute

    ensure
      file&.close
    end
  end
end
