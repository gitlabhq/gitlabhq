class GitoliteWorker
  include Sidekiq::Worker
  include Gitolited

  sidekiq_options queue: :gitolite

  def perform(action, *arg)
    gitolite.send(action, *arg)
  end
end
