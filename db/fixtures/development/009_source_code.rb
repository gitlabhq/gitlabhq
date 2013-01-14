root = Gitlab.config.gitolite.repos_path

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

  next if File.exists?(project_path)

  cmds = [
    "cd #{root} && sudo -u git -H git clone --bare #{project[:git]} ./#{project[:path]}",
    "sudo ln -s ./lib/hooks/post-receive #{project_path}/hooks/post-receive",
    "sudo chown git:git -R #{project_path}",
    "sudo chmod 770 -R #{project_path}",
  ]

  cmds.each do |cmd|
    puts cmd.yellow
    `#{cmd}`
  end
end

puts "OK".green
