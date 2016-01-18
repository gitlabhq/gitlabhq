module Gitlab
  class TaskAbortedByUserError < StandardError; end
end

String.disable_colorization = true unless STDOUT.isatty

# Prevent StateMachine warnings from outputting during a cron task
StateMachines::Machine.ignore_method_conflicts = true if ENV['CRON']

namespace :gitlab do

  # Ask if the user wants to continue
  #
  # Returns "yes" the user chose to continue
  # Raises Gitlab::TaskAbortedByUserError if the user chose *not* to continue
  def ask_to_continue
    answer = prompt("Do you want to continue (yes/no)? ".blue, %w{yes no})
    raise Gitlab::TaskAbortedByUserError unless answer == "yes"
  end

  # Check which OS is running
  #
  # It will primarily use lsb_relase to determine the OS.
  # It has fallbacks to Debian, SuSE, OS X and systems running systemd.
  def os_name
    os_name = run(%W(lsb_release -irs))
    os_name ||= if File.readable?('/etc/system-release')
                  File.read('/etc/system-release')
                end
    os_name ||= if File.readable?('/etc/debian_version')
                  debian_version = File.read('/etc/debian_version')
                  "Debian #{debian_version}"
                end
    os_name ||= if File.readable?('/etc/SuSE-release')
                  File.read('/etc/SuSE-release')
                end
    os_name ||= if os_x_version = run(%W(sw_vers -productVersion))
                  "Mac OS X #{os_x_version}"
                end
    os_name ||= if File.readable?('/etc/os-release')
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
  # see also #run
  # see also String#match
  def run_and_match(command, regexp)
    run(command).try(:match, regexp)
  end

  # Runs the given command
  #
  # Returns nil if the command was not found
  # Returns the output of the command otherwise
  #
  # see also #run_and_match
  def run(command)
    output, _ = Gitlab::Popen.popen(command)
    output
  rescue Errno::ENOENT
    '' # if the command does not exist, return an empty string
  end

  def uid_for(user_name)
    run(%W(id -u #{user_name})).chomp.to_i
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
      current_user = run(%W(whoami)).chomp
      unless current_user == gitlab_user
        puts " Warning ".colorize(:black).on_yellow
        puts "  You are running as user #{current_user.magenta}, we hope you know what you are doing."
        puts "  Things may work\/fail for the wrong reasons."
        puts "  For correct results you should run this as user #{gitlab_user.magenta}."
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
    IO.popen(%W(find #{Gitlab.config.gitlab_shell.repos_path} -mindepth 2 -maxdepth 2 -type d -name *.git)) do |find|
      find.each_line do |path|
        yield path.chomp
      end
    end
  end
end
