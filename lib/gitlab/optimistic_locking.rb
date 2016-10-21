module Gitlab
  class OptimisticLocking
    def self.retry_lock(subject, &block)
      loop do
        begin
          subject.transaction do
            return block.call(subject)
          end
        rescue ActiveRecord::StaleObjectError
          subject.reload
        end
      end
    end
  end
end
