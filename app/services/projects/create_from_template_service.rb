# frozen_string_literal: true

module Projects
  class CreateFromTemplateService < BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      file = Gitlab::ProjectTemplate.find(template_name)&.file

      override_params = params.dup
      params[:file] = file

      GitlabProjectsImportService.new(current_user, params, override_params).execute
    ensure
      file&.close
    end

    def template_name
      strong_memoize(:template_name) do
        params.delete(:template_name).presence
      end
    end
  end
end
