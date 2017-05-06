class ProjectUrlConstrainer
  def matches?(request)
    namespace_path = request.params[:namespace_id]
    project_path = request.params[:project_id] || request.params[:id]
    full_path = namespace_path + '/' + project_path

    return false unless DynamicPathValidator.valid?(full_path)

    Project.find_by_full_path(full_path, follow_redirects: request.get?).present?
  end
end
