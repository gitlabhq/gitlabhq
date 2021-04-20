# frozen_string_literal: true

module FindClosest
  # Find the closest node of a given type above this node, and return the domain object
  def closest_parent(type, parent)
    parent = parent.try(:parent) while parent && parent.object.class != type
    return unless parent

    parent.object.object
  end
end
