class GroupUrlConstrainer
  def matches?(request)
    id = request.params[:id]

    return false unless DynamicPathValidator.valid_full_path?(id)

    Group.find_by_full_path(id).present?
  end
end
