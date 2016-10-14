class BuildHooksWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:execute_hooks)
  end
end
