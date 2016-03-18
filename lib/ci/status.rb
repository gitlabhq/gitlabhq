module Ci
  class Status
    def self.get_status(statuses)
      if statuses.none?
        'skipped'
      elsif statuses.all? { |status| status.success? || status.ignored? }
        'success'
      elsif statuses.all?(&:pending?)
        'pending'
      elsif statuses.any?(&:running?) || statuses.any?(&:pending?)
        'running'
      elsif statuses.all?(&:canceled?)
        'canceled'
      else
        'failed'
      end
    end
  end
end
