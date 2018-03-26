module Gitlab
  module OptimisticLocking
    module_function

    def retry_lock(subject, retries = 100, &block)
      loop do
        begin
          ActiveRecord::Base.transaction do
            return yield(subject) # rubocop:disable Cop/AvoidReturnFromBlocks
          end
        rescue ActiveRecord::StaleObjectError
          retries -= 1
          raise unless retries >= 0

          subject.reload
        end
      end
    end

    alias_method :retry_optimistic_lock, :retry_lock
  end
end
