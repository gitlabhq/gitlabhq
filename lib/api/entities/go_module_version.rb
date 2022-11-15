# frozen_string_literal: true

module API
  module Entities
    class GoModuleVersion < Grape::Entity
      expose :name, as: 'Version', documentation: { type: 'string', example: 'v1.0.0' }
      expose :time, as: 'Time', documentation: { type: 'string', example: '1617822312 -0600' }
    end
  end
end
