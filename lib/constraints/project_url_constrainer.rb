# frozen_string_literal: true

module Constraints
  class ProjectUrlConstrainer
    def matches?(request)
      namespace_path = request.params[:namespace_id]
      project_path = request.params[:project_id] || request.params[:id]
      full_path = [namespace_path, project_path].join('/')

      ProjectPathValidator.valid_path?(full_path)
    end
  end
end
