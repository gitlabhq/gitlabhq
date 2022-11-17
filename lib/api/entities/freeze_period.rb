# frozen_string_literal: true

module API
  module Entities
    class FreezePeriod < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :freeze_start, documentation: { type: 'string', example: '0 23 * * 5' }
      expose :freeze_end, documentation: { type: 'string', example: '0 8 * * 1' }
      expose :cron_timezone, documentation: { type: 'string', example: 'UTC' }
      expose :created_at, :updated_at, documentation: { type: 'dateTime', example: '2020-05-15T17:03:35.702Z' }
    end
  end
end
