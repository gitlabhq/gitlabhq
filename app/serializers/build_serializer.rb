class BuildSerializer < BaseSerializer
  entity BuildEntity

  def represent_status(resource, opts = {}, entity_class = nil)
    data = represent(resource, { only: [:status] })
    data.fetch(:status, {})
  end
end
