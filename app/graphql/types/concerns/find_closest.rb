# frozen_string_literal: true

module FindClosest
  # Find the closest node which has any of the given types above this node, and return the domain object
  def closest_parent(types, parent)
    while parent

      if types.any? {|type| parent.object.instance_of? type}
        return parent.object.object
      else
        parent = parent.try(:parent)
      end
    end
  end
end
