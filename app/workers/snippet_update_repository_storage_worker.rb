# frozen_string_literal: true

# This is a compatibility class to avoid calling a non-existent
# class from sidekiq during deployment.
#
# This class was moved to a namespace in https://gitlab.com/gitlab-org/gitlab/-/issues/299853.
# we cannot remove this class entirely because there can be jobs
# referencing it.
#
# We can get rid of this class in 14.0
# https://gitlab.com/gitlab-org/gitlab/-/issues/322393
class SnippetUpdateRepositoryStorageWorker < Snippets::UpdateRepositoryStorageWorker # rubocop:disable Scalability/IdempotentWorker
  idempotent!
  urgency :throttled
end
