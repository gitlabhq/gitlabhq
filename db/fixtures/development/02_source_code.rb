gitlab_shell_path =  File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
root = Gitlab.config.gitlab_shell.repos_path

projects = [
  { path: 'underscore.git',              git: 'https://github.com/documentcloud/underscore.git' },
  { path: 'diaspora.git',                git: 'https://github.com/diaspora/diaspora.git' },
  { path: 'brightbox/brightbox-cli.git', git: 'https://github.com/brightbox/brightbox-cli.git' },
  { path: 'brightbox/puppet.git',        git: 'https://github.com/brightbox/puppet.git' },
  { path: 'gitlab/gitlabhq.git',        git: 'https://github.com/gitlabhq/gitlabhq.git' },
  { path: 'gitlab/gitlab-ci.git',       git: 'https://github.com/gitlabhq/gitlab-ci.git' },
  { path: 'gitlab/gitlab-recipes.git', git: 'https://github.com/gitlabhq/gitlab-recipes.git' },
]

projects.each do |project|
  project_path = File.join(root, project[:path])

  if File.exists?(project_path)
    print '-'
    next
  end
  if system("#{gitlab_shell_path}/gitlab-shell/bin/gitlab-projects import-project #{project[:path]} #{project[:git]}")
    print '.'
  else
    print 'F'
  end
end

puts "OK".green

