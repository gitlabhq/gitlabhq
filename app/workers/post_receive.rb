class PostReceive
  @queue = :post_receive

  def self.perform(reponame, oldrev, newrev, ref, author_key_id)
    project = Project.find_by_path(reponame)
    return false if project.nil?

    # Ignore push from non-gitlab users
    return false unless Key.find_by_identifier(author_key_id)

    project.trigger_post_receive(oldrev, newrev, ref, author_key_id)
  end
end
