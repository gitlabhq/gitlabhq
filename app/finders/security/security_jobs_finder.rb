# frozen_string_literal: true

# Security::SecurityJobsFinder
#
# Used to find jobs (builds) that are related to the Secure products:
# SAST, DAST, Dependency Scanning and Container Scanning
#
# Arguments:
#   params:
#     pipeline:              required, only jobs for the specified pipeline will be found
#     job_types:             required, array of job types that should be returned, defaults to all job types

module Security
  class SecurityJobsFinder < JobsFinder
    def self.allowed_job_types
      Enums::Security.analyzer_types.keys
    end
  end
end
