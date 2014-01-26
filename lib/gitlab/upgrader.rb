require_relative "version_info"

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
      git_tags = `git ls-remote --tags origin | grep tags\/v#{current_version.major}`
      git_tags = git_tags.lines.to_a.select { |version| version =~ /v\d\.\d\.\d\Z/ }
      last_tag = git_tags.last.match(/v\d\.\d\.\d/).to_s
    end

    def update_commands
      {
        "Stash changed files" => "git stash",
        "Get latest code" => "git fetch",
        "Switch to new version" => "git checkout v#{latest_version}",
        "Install gems" => "bundle",
        "Migrate DB" => "bundle exec rake db:migrate RAILS_ENV=production",
        "Recompile assets" => "bundle exec rake assets:clean assets:precompile RAILS_ENV=production",
        "Clear cache" => "bundle exec rake cache:clear RAILS_ENV=production"
      }
    end

    def upgrade
      update_commands.each do |title, cmd|
        puts title
        puts " -> #{cmd}"
        if system(cmd)
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
