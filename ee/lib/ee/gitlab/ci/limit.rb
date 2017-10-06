module EE
  module Gitlab
    module Ci
      ##
      # Abstract base class for CI/CD Quotas
      #
      class Limit
        def initialize(_context, _resource)
        end

        def enabled?
          raise NotImplementedError
        end

        def exceeded?
          raise NotImplementedError
        end

        def message
          raise NotImplementedError
        end
      end
    end
  end
end
