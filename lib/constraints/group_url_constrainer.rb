class GroupUrlConstrainer
  def matches?(request)
    id = request.params[:group_id] || request.params[:id]

    return false unless DynamicPathValidator.valid_namespace_path?(id)

    Group.find_by_full_path(id, follow_redirects: request.get?).present?
  end
end
