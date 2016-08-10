module Gitlab
  module Badge
    module Coverage
      ##
      # Test coverage report badge
      #
      class Report < Badge::Base
        def initialize(project, ref, job = nil)
          @project = project
          @ref = ref
          @job = job
        end

        def coverage
        end
      end
    end
  end
end
