# frozen_string_literal: true

class AuthorizedProjectsWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :system_access
  urgency :high
  weight 2
  idempotent!
  loggable_arguments 1 # For the job waiter key

  def perform(user_id)
    user = User.find_by_id(user_id)

    user&.refresh_authorized_projects(source: self.class.name)
  end
end
