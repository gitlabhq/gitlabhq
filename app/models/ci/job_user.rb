module Ci
  # Empty class to differenciate between users that have authenticated by
  # CI_JOB_TOKEN
  class JobUser < User
    def abilities
      %i[read_build read_project access_git access_api]
    end
  end
end
