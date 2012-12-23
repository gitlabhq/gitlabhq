module Gitlab
  class TaskAbortedByUserError < StandardError; end
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

  # Prompt the user to input something
  #
  # message - the message to display before input
  # choices - array of strings of acceptible answers or nil for any answer
  #
  # Returns the user's answer
  def prompt(message, choices = nil)
    begin
      print(message)
      answer = STDIN.gets.chomp
    end while choices.present? && !choices.include?(answer)
    answer
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

  def warn_user_is_not_gitlab
    unless @warned_user_not_gitlab
      current_user = run("whoami").chomp
      unless current_user == "gitlab"
        puts "#{Colored.color(:black)+Colored.color(:on_yellow)} Warning #{Colored.extra(:clear)}"
        puts "  You are running as user #{current_user.magenta}, we hope you know what you are doing."
        puts "  Things may work\/fail for the wrong reasons."
        puts "  For correct results you should run this as user #{"gitlab".magenta}."
        puts ""
      end
      @warned_user_not_gitlab = true
    end
  end
end
