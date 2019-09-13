# frozen_string_literal: true

module Ci
  class CancelUserPipelinesService
    # rubocop: disable CodeReuse/ActiveRecord
    # This is a bug with CodeReuse/ActiveRecord cop
    # https://gitlab.com/gitlab-org/gitlab/issues/32332
    def execute(user)
      user.pipelines.cancelable.find_each(&:cancel_running)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
