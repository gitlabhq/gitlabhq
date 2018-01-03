module Projects
  class CreateFromTemplateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      params[:file] = Gitlab::ProjectTemplate.find(params[:template_name]).file

      GitlabProjectsImportService.new(@current_user, @params).execute
    ensure
      params[:file]&.close
    end
  end
end
