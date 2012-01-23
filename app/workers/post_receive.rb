class PostReceive
  @queue = :post_receive

  def self.perform(reponame, oldrev, newrev, ref)
    project = Project.find_by_path(reponame)
    return false if project.nil?

    project.execute_web_hooks(oldrev, newrev, ref)
  end
end
