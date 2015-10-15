module Ci
  class Status
    def self.get_status(statuses)
      statuses.reject! { |status| status.try(&:allow_failure?) }

      if statuses.none?
        'skipped'
      elsif statuses.all?(&:success?)
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
