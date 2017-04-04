class ProjectUrlConstrainer
  def matches?(request)
    namespace_path = request.params[:namespace_id]
    project_path = request.params[:project_id] || request.params[:id]
    full_path = namespace_path + '/' + project_path

    unless ProjectPathValidator.valid?(project_path)
      return false
    end

    Project.find_by_full_path(full_path).present?
  end
end
