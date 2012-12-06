namespace :gitlab do
  namespace :app do
    desc "GITLAB | Get Information about this installation"
    task :info => :environment  do

      puts ""
      puts "Gitlab information".yellow
      puts "Version:\t#{Gitlab::Version}"
      puts "Revision:\t#{Gitlab::Revision}"

      # check which os is running
      if Kernel.system('lsb_release > /dev/null 2>&1')
        os_name = `lsb_release -irs`
      elsif File.exists?('/etc/system-release') && File.readable?('/etc/system-release')
        os_name = File.read('/etc/system-release')
      elsif File.exists?('/etc/debian_version') && File.readable?('/etc/debian_version')
        debian_version = File.read('/etc/debian_version')
        os_name = "Debian #{debian_version}"
      end
      os_name = os_name.gsub(/\n/, '')

      # check gitolite version
      gitolite_version_file = "#{Gitlab.config.git_base_path}/../gitolite/src/VERSION"
      if File.exists?(gitolite_version_file) && File.readable?(gitolite_version_file)
        gitolite_version = File.read(gitolite_version_file)
      else
        gitolite_version = 'unknown'
      end

      puts ""
      puts "System information".yellow
      puts "System:\t\t#{os_name}"
      puts "Home:\t\t#{ENV['HOME']}"
      puts "User:\t\t#{ENV['LOGNAME']}"
      puts "Ruby:\t\t#{ENV['RUBY_VERSION']}"
      puts "Gems:\t\t#{`gem --version`}"

      puts ""
      puts "Gitolite information".yellow
      puts "Version:\t#{gitolite_version}"
      puts "Admin URI:\t#{Gitlab.config.git_host.admin_uri}"
      puts "Base Path:\t#{Gitlab.config.git_base_path}"
      puts "Hook Path:\t#{Gitlab.config.git_hooks_path}"
      puts "Git:\t\t#{Gitlab.config.git.path}"

    end
  end
end
