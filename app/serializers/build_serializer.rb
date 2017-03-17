class BuildSerializer < BaseSerializer
  entity BuildEntity

  def represent(resource, opts = {})
    super(resource, opts)
  end

  def represent_status(resource)
    data = represent(resource, { only: [:status] })
    data.fetch(:status, {})
  end
end
