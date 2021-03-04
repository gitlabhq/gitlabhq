# frozen_string_literal: true

# Security::LicenseScanningJobsFinder
#
# Used to find jobs (builds) that are related to the License Management.
#
# Arguments:
#   params:
#     pipeline:              required, only jobs for the specified pipeline will be found
#     job_types:             required, array of job types that should be returned, defaults to all job types

module Security
  class LicenseComplianceJobsFinder < JobsFinder
    def self.allowed_job_types
      [:license_scanning]
    end
  end
end
