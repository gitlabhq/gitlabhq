# frozen_string_literal: true

class ClusterSerializer < BaseSerializer
  entity ClusterEntity

  def represent_status(resource)
    represent(resource, { only: [:status, :status_reason, :applications] })
  end
end
