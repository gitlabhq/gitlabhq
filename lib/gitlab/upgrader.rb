module Gitlab
  class Upgrader
    def execute
      puts "GitLab #{current_version.major} upgrade tool"
      puts "Your version is #{current_version}"
      puts "Latest available version for GitLab #{current_version.major} is #{latest_version}"

      if latest_version?
        puts "You are using the latest GitLab version"
      else
        puts "Newer GitLab version is available"

        answer = if ARGV.first == "-y"
                   "yes"
                 else
                   prompt("Do you want to upgrade (yes/no)? ", %w{yes no})
                 end

        if answer == "yes"
          upgrade
        else
          exit 0
        end
      end
    end

    def latest_version?
      current_version >= latest_version
    end

    def current_version
      @current_version ||= Gitlab::VersionInfo.parse(current_version_raw)
    end

    def latest_version
      @latest_version ||= Gitlab::VersionInfo.parse(latest_version_raw)
    end

    def current_version_raw
      File.read(File.join(gitlab_path, "VERSION")).strip
    end

    def latest_version_raw
      git_tags = fetch_git_tags
      git_tags = git_tags.select { |version| version =~ /v\d+\.\d+\.\d+\Z/ }
      git_versions = git_tags.map { |tag| Gitlab::VersionInfo.parse(tag.match(/v\d+\.\d+\.\d+/).to_s) }
      "v#{git_versions.sort.last}"
    end

    def fetch_git_tags
      remote_tags, _ = Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} ls-remote --tags https://gitlab.com/gitlab-org/gitlab-ce.git))
      remote_tags.split("\n").grep(%r{tags/v#{current_version.major}})
    end

    def update_commands
      {
        "Stash changed files" => %W(#{Gitlab.config.git.bin_path} stash),
        "Get latest code" => %W(#{Gitlab.config.git.bin_path} fetch),
        "Switch to new version" => %W(#{Gitlab.config.git.bin_path} checkout v#{latest_version}),
        "Install gems" => %w(bundle),
        "Migrate DB" => %w(bundle exec rake db:migrate),
        "Recompile assets" => %w(bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile),
        "Clear cache" => %w(bundle exec rake cache:clear)
      }
    end

    def env
      {
        'RAILS_ENV' => 'production',
        'NODE_ENV' => 'production'
      }
    end

    def upgrade
      update_commands.each do |title, cmd|
        puts title
        puts " -> #{cmd.join(' ')}"

        if system(env, *cmd)
          puts " -> OK"
        else
          puts " -> FAILED"
          puts "Failed to upgrade. Try to repeat task or proceed with upgrade manually "
          exit 1
        end
      end

      puts "Done"
    end

    def gitlab_path
      File.expand_path(File.join(File.dirname(__FILE__), '../..'))
    end

    # Prompt the user to input something
    #
    # message - the message to display before input
    # choices - array of strings of acceptable answers or nil for any answer
    #
    # Returns the user's answer
    def prompt(message, choices = nil)
      begin
        print(message)
        answer = STDIN.gets.chomp
      end while !choices.include?(answer)
      answer
    end
  end
end
