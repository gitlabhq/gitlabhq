require 'constraints/namespace_url_constrainer'

class UserUrlConstrainer < NamespaceUrlConstrainer
  def find_resource(id)
    User.find_by('lower(username) = ?', id.downcase)
  end
end
