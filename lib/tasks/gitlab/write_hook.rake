namespace :gitlab do
  namespace :gitolite do
    desc "GITLAB | Write GitLab hook for gitolite"
    task :write_hooks => :environment  do
      gitolite_hooks_path = File.join(Gitlab.config.git_hooks_path, "common")
      gitlab_hooks_path = Rails.root.join("lib", "hooks")
      gitlab_hook_files = ['post-receive']

      gitlab_hook_files.each do |file_name|
        source = File.join(gitlab_hooks_path, file_name)
        dest = File.join(gitolite_hooks_path, file_name)

        puts "sudo -u root cp #{source} #{dest}".yellow
        `sudo -u root cp #{source} #{dest}`

        puts "sudo -u root chown git:git #{dest}".yellow
        `sudo -u root chown git:git #{dest}`
      end
    end
  end
end
