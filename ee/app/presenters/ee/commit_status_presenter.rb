# frozen_string_literal: true
module EE
  module CommitStatusPresenter
    EE_CALLOUT_FAILURE_MESSAGES = {
      protected_environment_failure: 'The environment this job is deploying to is protected. Only users with permission may successfully run this job'
    }.freeze
  end
end
