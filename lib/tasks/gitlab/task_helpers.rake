module Gitlab
  class TaskAbortedByUserError < StandardError; end
end

unless STDOUT.isatty
  module Colored
    extend self

    def colorize(string, options={})
      string
    end
  end
end

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
    os_name = run("lsb_release -irs")
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
    os_name ||= if os_x_version = run("sw_vers -productVersion")
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
    unless `#{command} 2>/dev/null`.blank?
      `#{command}`
    end
  end

  def uid_for(user_name)
    run("id -u #{user_name}").chomp.to_i
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
      current_user = run("whoami").chomp
      unless current_user == gitlab_user
        puts "#{Colored.color(:black)+Colored.color(:on_yellow)} Warning #{Colored.extra(:clear)}"
        puts "  You are running as user #{current_user.magenta}, we hope you know what you are doing."
        puts "  Things may work\/fail for the wrong reasons."
        puts "  For correct results you should run this as user #{gitlab_user.magenta}."
        puts ""
      end
      @warned_user_not_gitlab = true
    end
  end
end
