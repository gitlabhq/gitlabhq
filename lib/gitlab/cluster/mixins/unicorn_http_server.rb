# frozen_string_literal: true

module Gitlab
  module Cluster
    module Mixins
      module UnicornHttpServer
        def self.prepended(base)
          unless base.method_defined?(:reexec) && base.method_defined?(:stop)
            raise 'missing method Unicorn::HttpServer#reexec or Unicorn::HttpServer#stop'
          end
        end

        def reexec
          Gitlab::Cluster::LifecycleEvents.do_before_graceful_shutdown

          super
        end

        # The stop on non-graceful shutdown is executed twice:
        # `#stop(false)` and `#stop`.
        #
        # The first stop will wipe-out all workers, so we need to check
        # the flag and a list of workers
        def stop(graceful = true)
          if graceful && @workers.any? # rubocop:disable Gitlab/ModuleWithInstanceVariables
            Gitlab::Cluster::LifecycleEvents.do_before_graceful_shutdown
          end

          super
        end
      end
    end
  end
end
