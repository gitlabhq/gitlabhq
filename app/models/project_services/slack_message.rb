require 'slack-notifier'

class SlackMessage
  def initialize(params)
    @after = params.fetch(:after)
    @before = params.fetch(:before)
    @commits = params.fetch(:commits, [])
    @project_name = params.fetch(:project_name)
    @project_url = params.fetch(:project_url)
    @ref = params.fetch(:ref).gsub('refs/heads/', '')
    @username = params.fetch(:user_name)
  end

  def compose
    format(message)
  end

  private

  attr_reader :after
  attr_reader :before
  attr_reader :commits
  attr_reader :project_name
  attr_reader :project_url
  attr_reader :ref
  attr_reader :username

  def message
    if new_branch?
      new_branch_message
    elsif removed_branch?
      removed_branch_message
    else
      push_message << commit_messages
    end
  end

  def format(string)
    Slack::Notifier::LinkFormatter.format(string)
  end

  def new_branch_message
    "#{username} pushed new branch #{branch_link} to #{project_link}"
  end

  def removed_branch_message
    "#{username} removed branch #{ref} from #{project_link}"
  end

  def push_message
    "#{username} pushed to branch #{branch_link} of #{project_link} (#{compare_link})"
  end

  def commit_messages
    commits.each_with_object('') do |commit, str|
      str << compose_commit_message(commit)
    end
  end

  def compose_commit_message(commit)
    id = commit.fetch(:id)[0..5]
    message = commit.fetch(:message)
    url = commit.fetch(:url)

    "\n - #{message} ([#{id}](#{url}))"
  end

  def new_branch?
    before =~ /000000/
  end

  def removed_branch?
    after =~ /000000/
  end

  def branch_url
    "#{project_url}/commits/#{ref}"
  end

  def compare_url
    "#{project_url}/compare/#{before}...#{after}"
  end

  def branch_link
    "[#{ref}](#{branch_url})"
  end

  def project_link
    "[#{project_name}](#{project_url})"
  end

  def compare_link
    "[Compare changes](#{compare_url})"
  end
end
