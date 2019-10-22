# frozen_string_literal: true

module Gitlab
  module Cluster
    module Mixins
      module UnicornHttpServer
        def self.prepended(base)
          raise 'missing method Unicorn::HttpServer#reexec' unless base.method_defined?(:reexec)
        end

        def reexec
          Gitlab::Cluster::LifecycleEvents.do_before_phased_restart

          super
        end
      end
    end
  end
end
