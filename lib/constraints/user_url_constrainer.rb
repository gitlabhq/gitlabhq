require_relative 'constrainer_helper'

class UserUrlConstrainer
  include ConstrainerHelper

  def matches?(request)
    id = extract_resource_path(request.path)

    if id =~ Gitlab::Regex.namespace_regex
      !!User.find_by('lower(username) = ?', id.downcase)
    else
      false
    end
  end
end
