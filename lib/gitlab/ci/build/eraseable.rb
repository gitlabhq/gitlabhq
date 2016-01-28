module Gitlab
  module Ci
    module Build
      class Eraseable
        def initialize(build)
          @build = build
        end

        def erase!
          raise NotImplementedError
        end

        def erased?
          @build.artifacts_file.exists? && @build.artifacts_metadata.exists?
        end

        private

        def trace_file
          raise NotImplementedError
        end
      end
    end
  end
end
