namespace :gitlab do

  # Check which OS is running
  #
  # It will primarily use lsb_relase to determine the OS.
  # It has fallbacks to Debian, SuSE and OS X.
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
    os_name.try(:squish!)
  end

  # Runs the given command and matches the output agains the given pattern
  #
  # Returns nil if nothing matched
  # Retunrs the MatchData if the pattern matched
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
    group_line = File.read("/etc/group").lines.select{|l| l.start_with?("#{group_name}:")}.first
    group_line.split(":")[2].to_i
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
