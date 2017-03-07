require 'rainbow/ext/string'

module Gitlab
  TaskFailedError = Class.new(StandardError)
  TaskAbortedByUserError = Class.new(StandardError)

  module TaskHelpers
    # Ask if the user wants to continue
    #
    # Returns "yes" the user chose to continue
    # Raises Gitlab::TaskAbortedByUserError if the user chose *not* to continue
    def ask_to_continue
      answer = prompt("Do you want to continue (yes/no)? ".color(:blue), %w{yes no})
      raise Gitlab::TaskAbortedByUserError unless answer == "yes"
    end

    # Check which OS is running
    #
    # It will primarily use lsb_relase to determine the OS.
    # It has fallbacks to Debian, SuSE, OS X and systems running systemd.
    def os_name
      os_name = run_command(%w(lsb_release -irs))
      os_name ||=
        if File.readable?('/etc/system-release')
          File.read('/etc/system-release')
        elsif File.readable?('/etc/debian_version')
          "Debian #{File.read('/etc/debian_version')}"
        elsif File.readable?('/etc/SuSE-release')
          File.read('/etc/SuSE-release')
        elsif os_x_version = run_command(%w(sw_vers -productVersion))
          "Mac OS X #{os_x_version}"
        elsif File.readable?('/etc/os-release')
          File.read('/etc/os-release').match(/PRETTY_NAME=\"(.+)\"/)[1]
        end

      os_name.try(:squish!)
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
      end while choices.present? && !choices.include?(answer)
      answer
    end

    # Runs the given command and matches the output against the given pattern
    #
    # Returns nil if nothing matched
    # Returns the MatchData if the pattern matched
    #
    # see also #run_command
    # see also String#match
    def run_and_match(command, regexp)
      run_command(command).try(:match, regexp)
    end

    # Runs the given command
    #
    # Returns '' if the command was not found
    # Returns the output of the command otherwise
    #
    # see also #run_and_match
    def run_command(command)
      output, _ = Gitlab::Popen.popen(command)
      output
    rescue Errno::ENOENT
      '' # if the command does not exist, return an empty string
    end

    # Runs the given command and raises a Gitlab::TaskFailedError exception if
    # the command does not exit with 0
    #
    # Returns the output of the command otherwise
    def run_command!(command)
      output, status = Gitlab::Popen.popen(command)

      raise Gitlab::TaskFailedError unless status.zero?

      output
    end

    def uid_for(user_name)
      run_command(%W(id -u #{user_name})).chomp.to_i
    end

    def gid_for(group_name)
      begin
        Etc.getgrnam(group_name).gid
      rescue ArgumentError # no group
        "group #{group_name} doesn't exist"
      end
    end

    def warn_user_is_not_gitlab
      unless @warned_user_not_gitlab
        gitlab_user = Gitlab.config.gitlab.user
        current_user = run_command(%w(whoami)).chomp
        unless current_user == gitlab_user
          puts " Warning ".color(:black).background(:yellow)
          puts "  You are running as user #{current_user.color(:magenta)}, we hope you know what you are doing."
          puts "  Things may work\/fail for the wrong reasons."
          puts "  For correct results you should run this as user #{gitlab_user.color(:magenta)}."
          puts ""
        end
        @warned_user_not_gitlab = true
      end
    end

    # Tries to configure git itself
    #
    # Returns true if all subcommands were successfull (according to their exit code)
    # Returns false if any or all subcommands failed.
    def auto_fix_git_config(options)
      if !@warned_user_not_gitlab
        command_success = options.map do |name, value|
          system(*%W(#{Gitlab.config.git.bin_path} config --global #{name} #{value}))
        end

        command_success.all?
      else
        false
      end
    end

    def all_repos
      Gitlab.config.repositories.storages.each do |name, path|
        IO.popen(%W(find #{path} -mindepth 2 -maxdepth 2 -type d -name *.git)) do |find|
          find.each_line do |path|
            yield path.chomp
          end
        end
      end
    end

    def repository_storage_paths_args
      Gitlab.config.repositories.storages.values
    end

    def user_home
      Rails.env.test? ? Rails.root.join('tmp/tests') : Gitlab.config.gitlab.user_home
    end

    def checkout_or_clone_tag(tag:, repo:, target_dir:)
      if Dir.exist?(target_dir)
        checkout_tag(tag, target_dir)
      else
        clone_repo(repo, target_dir)
      end

      reset_to_tag(tag, target_dir)
    end

    def clone_repo(repo, target_dir)
      run_command!(%W[#{Gitlab.config.git.bin_path} clone -- #{repo} #{target_dir}])
    end

    def checkout_tag(tag, target_dir)
      run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} fetch --tags --quiet])
      run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} checkout --quiet #{tag}])
    end

    def reset_to_tag(tag_wanted, target_dir)
      tag =
        begin
          # First try to checkout without fetching
          # to avoid stalling tests if the Internet is down.
          run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} describe -- #{tag_wanted}])
        rescue Gitlab::TaskFailedError
          run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} fetch origin])
          run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} describe -- origin/#{tag_wanted}])
        end

      if tag
        run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} reset --hard #{tag.strip}])
      else
        raise Gitlab::TaskFailedError
      end
    end
  end
end
