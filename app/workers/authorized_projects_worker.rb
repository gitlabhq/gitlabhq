# frozen_string_literal: true

class AuthorizedProjectsWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  prepend WaitableWorker

  feature_category :authentication_and_authorization
  urgency :high
  weight 2
  idempotent!
  loggable_arguments 1 # For the job waiter key

  # This is a workaround for a Ruby 2.3.7 bug. rspec-mocks cannot restore the
  # visibility of prepended modules. See https://github.com/rspec/rspec-mocks/issues/1231
  # for more details.
  if Rails.env.test?
    def self.bulk_perform_and_wait(args_list, timeout: 10)
    end

    def self.bulk_perform_inline(args_list)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(user_id)
    user = User.find_by(id: user_id)

    user&.refresh_authorized_projects(source: self.class.name)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
