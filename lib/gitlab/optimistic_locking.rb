module Gitlab
  module OptimisticLocking
    def retry_lock(subject, &block)
      while true do
        begin
          return yield subject
        rescue StaleObjectError
          subject.reload
        end
      end
    end
  end
end
