module Gitlab
  module Database
    module LoadBalancing
      # Modle injected into models in order to redirect connections to a
      # ConnectionProxy.
      module ModelProxy
        def connection
          LoadBalancing.proxy
        end
      end
    end
  end
end
