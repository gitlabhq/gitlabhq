class PostReceive
  @queue = :post_receive

  def self.perform(reponame, oldrev, newrev, ref, identifier)
    project = Project.find_by_path(reponame)
    return false if project.nil?

    # Ignore push from non-gitlab users
    user = if identifier.eql? Gitlab.config.gitolite_admin_key 
      email = project.commit(newrev).author.email
      User.find_by_email(email)
    elsif /^[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}$/.match(identifier)
      User.find_by_email(identifier)
    else
      Key.find_by_identifier(identifier).try(:user)
    end
    return false unless user

    project.trigger_post_receive(oldrev, newrev, ref, user)
  end
end
