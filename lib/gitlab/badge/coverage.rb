module Gitlab
  module Badge
    ##
    # Test coverage badge
    #
    class Coverage
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
