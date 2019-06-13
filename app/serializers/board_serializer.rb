# frozen_string_literal: true

class BoardSerializer < BaseSerializer
  entity BoardSimpleEntity

  def represent(resource, opts = {})
    if resource.respond_to?(:with_associations)
      resource = resource.with_associations
    end

    super
  end
end
