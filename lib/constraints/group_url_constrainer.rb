require_relative 'constrainer_helper'

class GroupUrlConstrainer
  include ConstrainerHelper

  def matches?(request)
    id = extract_resource_path(request.path)

    if id =~ Gitlab::Regex.namespace_regex
      !!Group.find_by_path(id)
    else
      false
    end
  end
end
