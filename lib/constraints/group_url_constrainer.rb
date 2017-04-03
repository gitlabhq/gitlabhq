class GroupUrlConstrainer
  def matches?(request)
    id = request.params[:id]

    return false unless valid?(id)

    Group.find_by_full_path(id).present?
  end

  private

  def valid?(id)
    id.split('/').all? do |namespace|
      NamespaceValidator.valid?(namespace)
    end
  end
end
