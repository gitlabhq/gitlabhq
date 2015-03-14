class SlackService
  class PushMessage < BaseMessage
    attr_reader :after
    attr_reader :before
    attr_reader :commits
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :ref
    attr_reader :ref_type
    attr_reader :user_name

    def initialize(params)
      @after = params[:after]
      @before = params[:before]
      @commits = params.fetch(:commits, [])
      @project_name = params[:project_name]
      @project_url = params[:project_url]
      @ref_type = Gitlab::Git.tag_ref?(params[:ref]) ? 'tag' : 'branch'
      @ref = Gitlab::Git.ref_name(params[:ref])
      @user_name = params[:user_name]
    end

    def pretext
      format(message)
    end

    def attachments
      return [] if new_branch? || removed_branch?

      commit_message_attachments
    end

    private

    def message
      if new_branch?
        new_branch_message
      elsif removed_branch?
        removed_branch_message
      else
        push_message
      end
    end

    def format(string)
      Slack::Notifier::LinkFormatter.format(string)
    end

    def new_branch_message
      "#{user_name} pushed new #{ref_type} #{branch_link} to #{project_link}"
    end

    def removed_branch_message
      "#{user_name} removed #{ref_type} #{ref} from #{project_link}"
    end

    def push_message
      "#{user_name} pushed to #{ref_type} #{branch_link} of #{project_link} (#{compare_link})"
    end

    def commit_messages
      commits.map { |commit| compose_commit_message(commit) }.join("\n")
    end

    def commit_message_attachments
      [{ text: format(commit_messages), color: attachment_color }]
    end

    def compose_commit_message(commit)
      author = commit[:author][:name]
      id = Commit.truncate_sha(commit[:id])
      message = commit[:message]
      url = commit[:url]

      "[#{id}](#{url}): #{message} - #{author}"
    end

    def new_branch?
      Gitlab::Git.blank_ref?(before)
    end

    def removed_branch?
      Gitlab::Git.blank_ref?(after)
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

    def attachment_color
      '#345'
    end
  end
end
