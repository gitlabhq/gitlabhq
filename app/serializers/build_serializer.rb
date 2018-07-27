# frozen_string_literal: true

class BuildSerializer < BaseSerializer
  entity JobEntity

  def represent_status(resource)
    data = represent(resource, { only: [:status] })
    data.fetch(:status, {})
  end
end
