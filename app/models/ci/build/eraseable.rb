module Ci
  class Build
    module Eraseable
      include ActiveSupport::Concern

      def erase!
        raise NotImplementedError
      end

      def erased?
        raise NotImpementedError
      end
    end
  end
end
