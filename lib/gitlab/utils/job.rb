# frozen_string_literal: true

module Gitlab
  module Utils
    module Job
      class << self
        def group_name(job_name)
          # [\b\s:] -> whitespace or column
          # (\[.*\])|(\d+[\s:\/\\]+\d+) -> variables/matrix or parallel-jobs numbers
          # {1,3} -> number of times that matches the variables/matrix or parallel-jobs numbers
          #          we limit this to 3 because of possible abuse
          regex = %r{([\b\s:]+((\[.*\])|(\d+[\s:\/\\]+\d+))){1,3}\s*\z}

          job_name.to_s.sub(regex, '').strip
        end
      end
    end
  end
end
