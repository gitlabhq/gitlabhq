module Gitlab
  module Kubernetes
    module Pod
      PENDING   = 'Pending'.freeze
      RUNNING   = 'Running'.freeze
      SUCCEEDED = 'Succeeded'.freeze
      FAILED    = 'Failed'.freeze
      UNKNOWN   = 'Unknown'.freeze
      PHASES    = [PENDING, RUNNING, SUCCEEDED, FAILED, UNKNOWN].freeze
    end
  end
end
