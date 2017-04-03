class BuildSerializer < BaseSerializer
  entity BuildEntity

  def represent_status(resource)
    data = represent(resource, { only: [:status] })
    data.fetch(:status, {})
  end
end
