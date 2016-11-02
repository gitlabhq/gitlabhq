module Gitlab::Ci
  class Config
    module Rule
      ##
      # Base abstract class for each logical rule in CI configuration.
      #
      class Base
        def initialize(job, config)
          @job = job
          @config = config
        end

        def apply!
          raise NotImplementedError
        end
      end
    end
  end
end
