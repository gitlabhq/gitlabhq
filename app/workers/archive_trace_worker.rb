# frozen_string_literal: true

class ArchiveTraceWorker < ::Ci::ArchiveTraceWorker # rubocop:disable Scalability/IdempotentWorker
  # DEPRECATED: Not triggered since https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64934/
end
