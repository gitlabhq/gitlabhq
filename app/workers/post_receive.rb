class PostReceive
  @queue = :post_receive

  def self.perform(reponame, oldrev, newrev, ref, identifier)
    project = Project.find_by_path(reponame)
    return false if project.nil?

    # Ignore push from non-gitlab users
    if /^[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}$/.match(identifier)
      return false unless user = User.find_by_email(identifier)
    else
      return false unless user = Key.find_by_identifier(identifier).try(:user)
    end

    project.trigger_post_receive(oldrev, newrev, ref, user)
  end
end
