class PostReceive
  @queue = :post_receive

  def self.perform(repo_path, oldrev, newrev, ref, identifier)
    repo_path.gsub!(Gitlab.config.gitolite.repos_path.to_s, "")
    repo_path.gsub!(/.git$/, "")
    repo_path.gsub!(/^\//, "")

    project = Project.find_with_namespace(repo_path)
    return false if project.nil?

    # Ignore push from non-gitlab users
    user = if identifier.eql? Gitlab.config.gitolite.admin_key
      email = project.commit(newrev).author.email rescue nil
      User.find_by_email(email) if email
    elsif /^[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}$/.match(identifier)
      User.find_by_email(identifier)
    else
      Key.find_by_identifier(identifier).try(:user)
    end
    return false unless user

    project.trigger_post_receive(oldrev, newrev, ref, user)
  end
end
