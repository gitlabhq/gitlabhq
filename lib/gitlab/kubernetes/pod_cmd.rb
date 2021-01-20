# frozen_string_literal: true

module Gitlab
  module Kubernetes
    # Miscellaneous commands that run in the helm-install-image pod, tuned to
    # the idiosynchrasies of the default shell of helm-install-image
    module PodCmd
      class << self
        def retry_command(command, times: 3)
          "for i in $(seq 1 #{times.to_i}); do #{command} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)"
        end
      end
    end
  end
end
