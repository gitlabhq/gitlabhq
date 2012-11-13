root = Gitlab.config.git_base_path

projects = [
  { path: 'underscore.git', git: 'https://github.com/documentcloud/underscore.git' },
  { path: 'diaspora.git', git: 'https://github.com/diaspora/diaspora.git' },
  { path: 'rails.git', git: 'https://github.com/rails/rails.git' },
]

projects.each do |project|
  project_path = File.join(root, project[:path])


  next if File.exists?(project_path)

  cmds = [
    "cd #{root} && sudo -u git -H git clone --bare #{project[:git]}",
    "sudo cp ./lib/hooks/post-receive #{project_path}/hooks/post-receive",
    "sudo chown git:git #{project_path}/hooks/post-receive"
  ]

  cmds.each do |cmd|
    puts cmd.yellow
    `#{cmd}`
  end
end

puts "OK".green
