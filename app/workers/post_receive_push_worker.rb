# frozen_string_literal: true

class PostReceivePushWorker
  include ApplicationWorker
  prepend WaitableWorker

  PUSH_SERVICES = %w(GitPushService GitTagPushService).freeze

  queue_namespace :post_receive

  # This is a workaround for a Ruby 2.3.7 bug. rspec-mocks cannot restore the
  # visibility of prepended modules. See https://github.com/rspec/rspec-mocks/issues/1231
  # for more details.
  if Rails.env.test?
    def self.bulk_perform_and_wait(args_list, timeout: 10)
    end
  end

  def perform(job_kind, project_id, user_id, oldrev, newrev, ref)
    return unless PUSH_SERVICES.include?(job_kind)

    project = Project.find_by(id: project_id)
    user = User.find_by(id: user_id)

    job_kind.constantize.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref).execute
  end
end
