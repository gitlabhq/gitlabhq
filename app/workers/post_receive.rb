class PostReceive
  @queue = :post_receive

  def self.perform(reponame, oldrev, newrev, ref, author_key_id)
    project = Project.find_by_path(reponame)
    return false if project.nil?

    project.observe_push(oldrev, newrev, ref, author_key_id)
    project.execute_web_hooks(oldrev, newrev, ref, author_key_id)
  end
end
