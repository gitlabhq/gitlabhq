# frozen_string_literal: true

module Ci
  class JobSerializer < BaseSerializer
    entity Ci::JobEntity

    def represent_status(resource)
      data = represent(resource, { only: [:status] })
      data.fetch(:status, {})
    end
  end
end
