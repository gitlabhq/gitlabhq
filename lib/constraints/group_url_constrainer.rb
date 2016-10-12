require 'constraints/namespace_url_constrainer'

class GroupUrlConstrainer < NamespaceUrlConstrainer
  def find_resource(id)
    Group.find_by_path(id)
  end
end
