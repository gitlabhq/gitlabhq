module Ci
  module ProjectStatus
    def status
      last_commit.status if last_commit
    end

    def broken?
      last_commit.failed? if last_commit
    end

    def success?
      last_commit.success? if last_commit
    end

    def broken_or_success?
      broken? || success?
    end

    def last_commit
      @last_commit ||= commits.last if commits.any?
    end

    def last_commit_date
      last_commit.try(:created_at)
    end

    def human_status
      status
    end

    def last_commit_for_ref(ref)
      commits.where(ref: ref).last
    end
  end
end
