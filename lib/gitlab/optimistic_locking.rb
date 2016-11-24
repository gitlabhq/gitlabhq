module Gitlab
  module OptimisticLocking
    extend self

    def retry_lock(subject, retries = 100, &block)
      loop do
        begin
          ActiveRecord::Base.transaction do
            return block.call(subject)
          end
        rescue ActiveRecord::StaleObjectError
          retries -= 1
          raise unless retries >= 0
          subject.reload
        end
      end
    end
  end
end
