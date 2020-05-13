# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshWithLowUrgencyWorker < ::AuthorizedProjectsWorker
    feature_category :authentication_and_authorization
    urgency :low

    idempotent!
  end
end
