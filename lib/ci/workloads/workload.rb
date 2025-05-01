# frozen_string_literal: true

module Ci
  module Workloads
    class Workload
      def job
        raise "not implemented"
      end

      def set_branch(branch)
        @branch = branch
      end
    end
  end
end
