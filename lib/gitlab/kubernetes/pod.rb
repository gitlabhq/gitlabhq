# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Pod
      PENDING   = 'Pending'
      RUNNING   = 'Running'
      SUCCEEDED = 'Succeeded'
      FAILED    = 'Failed'
      UNKNOWN   = 'Unknown'
      PHASES    = [PENDING, RUNNING, SUCCEEDED, FAILED, UNKNOWN].freeze
    end
  end
end
