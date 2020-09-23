# frozen_string_literal: true

class FeatureFlagSerializer < BaseSerializer
  include WithPagination
  entity FeatureFlagEntity

  def represent(resource, opts = {})
    super(resource, opts)
  end
end
