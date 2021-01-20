# frozen_string_literal: true

# This is a compatibility class to avoid calling a non-existent
# class from sidekiq during deployment.
#
# We're deploying the rename of this class in 13.9. Nevertheless,
# we cannot remove this class entirely because there can be jobs
# referencing it.
#
# We can get rid of this class in 13.10
# https://gitlab.com/gitlab-org/gitlab/-/issues/297580
#
module Projects
  class HousekeepingService < ::Repositories::HousekeepingService
  end
end
