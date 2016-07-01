class PostReceive
  include Sidekiq::Worker
  extend Gitlab::CurrentSettings

  sidekiq_options queue: :post_receive

  def perform(repo_path, identifier, changes)
    if path = Gitlab.config.repositories.storages.find { |p| repo_path.start_with?(p[1].to_s) }
      repo_path.gsub!(path[1].to_s, "")
    else
      log("Check gitlab.yml config for correct repositories.storages values. No repository storage path matches \"#{repo_path}\"")
    end

    post_received = Gitlab::GitPostReceive.new(repo_path, identifier, changes)

    if post_received.project.nil?
      log("Triggered hook for non-existing project with full path \"#{repo_path} \"")
      return false
    end

    if post_received.wiki?
      update_wiki_es_indexes(post_received)

      # Triggers repository update on secondary nodes when Geo is enabled
      Gitlab::Geo.notify_wiki_update(post_received.project) if Gitlab::Geo.enabled?
    elsif post_received.regular_project?
      process_project_changes(post_received)
    else
      log("Triggered hook for unidentifiable repository type with full path \"#{repo_path} \"")
      false
    end
  end

  def process_project_changes(post_received)
    post_received.changes.each do |change|
      oldrev, newrev, ref = change.strip.split(' ')

      @user ||= post_received.identify(newrev)

      unless @user
        log("Triggered hook for non-existing user \"#{post_received.identifier} \"")
        return false
      end

      if Gitlab::Git.tag_ref?(ref)
        GitTagPushService.new(post_received.project, @user, oldrev: oldrev, newrev: newrev, ref: ref).execute
      elsif Gitlab::Git.branch_ref?(ref)
        GitPushService.new(post_received.project, @user, oldrev: oldrev, newrev: newrev, ref: ref).execute
      end
    end
  end

  def update_wiki_es_indexes(post_received)
    return unless current_application_settings.elasticsearch_indexing?

    post_received.project.wiki.index_blobs
  end

  private

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end
