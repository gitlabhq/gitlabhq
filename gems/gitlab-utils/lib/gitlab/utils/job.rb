# frozen_string_literal: true

module Gitlab
  module Utils
    module Job
      # [\b\s:] -> whitespace or column
      # (\[.*\])|(\d+[\s:\/\\]+\d+) -> variables/matrix or parallel-jobs numbers
      # {1,3} -> number of times that matches the variables/matrix or parallel-jobs numbers
      #          we limit this to 3 because of possible abuse
      PARALLEL_VARIANT_REGEX = %r{([\b\s:]+((\[.*\])|(\d+[\s:/\\]+\d+))){1,3}\s*\z}

      class << self
        def group_name(job_name)
          job_name.to_s.sub(PARALLEL_VARIANT_REGEX, '').strip
        end

        def parallel_suffix(job_name)
          job_name.to_s[PARALLEL_VARIANT_REGEX] || ''
        end

        def node_total(job_options)
          # Jobs migrated from legacy data may store numeric `parallel` as a bare Integer.
          parallel = job_options&.dig(:parallel)
          parallel = parallel[:total] if parallel.is_a?(Hash)
          parallel || 1
        end
      end
    end
  end
end
