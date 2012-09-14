module GitHost
  def git_host
    Gitlab::Gitolite.new
  end
end
