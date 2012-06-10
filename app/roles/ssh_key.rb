module SshKey
  def update_repository
    Gitlab::GitHost.system.new.configure do |c|
      c.update_keys(identifier, key)
      c.update_projects(projects)
    end
  end

  def repository_delete_key
    Gitlab::GitHost.system.new.configure do |c|
      #delete key file is there is no identically deploy keys
      if !is_deploy_key || Key.where(:identifier => identifier).count() == 0
        c.delete_key(identifier)
      end
      c.update_projects(projects)
    end
  end
end
