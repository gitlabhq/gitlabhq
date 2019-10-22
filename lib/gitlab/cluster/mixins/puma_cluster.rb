# frozen_string_literal: true

module Gitlab
  module Cluster
    module Mixins
      module PumaCluster
        def self.prepended(base)
          raise 'missing method Puma::Cluster#stop_workers' unless base.method_defined?(:stop_workers)
        end

        def stop_workers
          Gitlab::Cluster::LifecycleEvents.do_before_phased_restart

          super
        end
      end
    end
  end
end
