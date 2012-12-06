namespace :gitlab do
  namespace :env do
    desc "GITLAB | Show information about GitLab and its environment"
    task :info => :environment  do

      # check which OS is running
      if Kernel.system('lsb_release > /dev/null 2>&1')
        os_name = `lsb_release -irs`
      elsif File.exists?('/etc/system-release') && File.readable?('/etc/system-release')
        os_name = File.read('/etc/system-release')
      elsif File.exists?('/etc/debian_version') && File.readable?('/etc/debian_version')
        debian_version = File.read('/etc/debian_version')
        os_name = "Debian #{debian_version}"
      end
      os_name = os_name.gsub(/\n/, '')

      # check if there is an RVM environment
      m, rvm_version = `rvm --version`.match(/rvm ([\d\.]+) /).to_a
      # check Bundler version
      m, bunder_version = `bundle --version`.match(/Bundler version ([\d\.]+)/).to_a
      # check Bundler version
      m, rake_version = `rake --version`.match(/rake, version ([\d\.]+)/).to_a

      puts ""
      puts "System information".yellow
      puts "System:\t\t#{os_name}"
      puts "Current User:\t#{`whoami`}"
      puts "Using RVM:\t#{rvm_version.present? ? "yes".green : "no"}"
      puts "RVM Version:\t#{rvm_version}" if rvm_version.present?
      puts "Ruby Version:\t#{ENV['RUBY_VERSION']}"
      puts "Gem Version:\t#{`gem --version`}"
      puts "Bundler Version:#{bunder_version}"
      puts "Rake Version:\t#{rake_version}"


      # check database adapter
      database_adapter = ActiveRecord::Base.connection.adapter_name.downcase

      project = Project.new(path: "some-project")
      project.path = "some-project"
      # construct clone URLs
      http_clone_url = project.http_url_to_repo
      ssh_clone_url  = project.ssh_url_to_repo

      puts ""
      puts "GitLab information".yellow
      puts "Version:\t#{Gitlab::Version}"
      puts "Revision:\t#{Gitlab::Revision}"
      puts "Directory:\t#{Rails.root}"
      puts "DB Adapter:\t#{database_adapter}"
      puts "URL:\t\t#{Gitlab.config.url}"
      puts "HTTP Clone URL:\t#{http_clone_url}"
      puts "SSH Clone URL:\t#{ssh_clone_url}"
      puts "Using LDAP:\t#{Gitlab.config.ldap_enabled? ? "yes".green : "no"}"
      puts "Using Omniauth:\t#{Gitlab.config.omniauth_enabled? ? "yes".green : "no"}"
      puts "Omniauth Providers:\t#{Gitlab.config.omniauth_providers}" if Gitlab.config.omniauth_enabled?



      # check Gitolite version
      gitolite_version_file = "#{Gitlab.config.git_base_path}/../gitolite/src/VERSION"
      if File.exists?(gitolite_version_file) && File.readable?(gitolite_version_file)
        gitolite_version = File.read(gitolite_version_file)
      else
        gitolite_version = 'unknown'
      end

      puts ""
      puts "Gitolite information".yellow
      puts "Version:\t#{gitolite_version}"
      puts "Admin URI:\t#{Gitlab.config.gitolite_admin_uri}"
      puts "Admin Key:\t#{Gitlab.config.gitolite_admin_key}"
      puts "Repositories:\t#{Gitlab.config.git_base_path}"
      puts "Hooks:\t\t#{Gitlab.config.git_hooks_path}"
      puts "Git:\t\t#{Gitlab.config.git.path}"

    end
  end
end
