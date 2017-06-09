class GroupUrlConstrainer
  def matches?(request)
<<<<<<< HEAD
    id = request.params[:group_id] || request.params[:id]

    return false unless DynamicPathValidator.valid_namespace_path?(id)
=======
    full_path = request.params[:group_id] || request.params[:id]

    return false unless DynamicPathValidator.valid_group_path?(full_path)
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259

    Group.find_by_full_path(full_path, follow_redirects: request.get?).present?
  end
end
