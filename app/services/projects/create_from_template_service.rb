module Projects
  class CreateFromTemplateService < BaseService
    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      params[:file] = Gitlab::ProjectTemplate.find(params[:template_title]).file

      @params[:from_template] = true
      GitlabProjectsImporterService.new(@current_user, @params).execute
    end
  end
end
