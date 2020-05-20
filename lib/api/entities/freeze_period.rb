# frozen_string_literal: true

module API
  module Entities
    class FreezePeriod < Grape::Entity
      expose :id
      expose :freeze_start, :freeze_end, :cron_timezone
      expose :created_at, :updated_at
    end
  end
end
