# frozen_string_literal: true

module ChatMessage
  class PushMessage < BaseMessage
    attr_reader :after
    attr_reader :before
    attr_reader :commits
    attr_reader :ref
    attr_reader :ref_type

    def initialize(params)
      super

      @after = params[:after]
      @before = params[:before]
      @commits = params.fetch(:commits, [])
      @ref_type = Gitlab::Git.tag_ref?(params[:ref]) ? 'tag' : 'branch'
      @ref = Gitlab::Git.ref_name(params[:ref])
    end

    def attachments
      return [] if new_branch? || removed_branch?
      return commit_messages if markdown

      commit_message_attachments
    end

    def activity
      {
        title: humanized_action(short: true),
        subtitle: "in #{project_link}",
        text: compare_link,
        image: user_avatar
      }
    end

    private

    def humanized_action(short: false)
      action, ref_link, target_link = compose_action_details
      text = [user_combined_name, action, ref_type, ref_link]
      text << target_link unless short
      text.join(' ')
    end

    def message
      humanized_action
    end

    def format(string)
      Slack::Notifier::LinkFormatter.format(string)
    end

    def commit_messages
      linebreak_chars = commit_message_html ? "<br/>\n<br/>\n" : "\n\n"
      commits.map { |commit| compose_commit_message(commit) }.join(linebreak_chars)
    end

    def commit_message_attachments
      [{ text: format(commit_messages), color: attachment_color }]
    end

    def compose_commit_message(commit)
      author = commit[:author][:name]
      id = Commit.truncate_sha(commit[:id])
      message = commit[:message]

      if commit_message_html
        message = message.gsub(Gitlab::Regex.breakline_regex, "<br/>\n")
      end

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

    def compose_action_details
      if new_branch?
        ['pushed new', branch_link, "to #{project_link}"]
      elsif removed_branch?
        ['removed', ref, "from #{project_link}"]
      else
        ['pushed to', branch_link, "of #{project_link} (#{compare_link})"]
      end
    end

    def attachment_color
      '#345'
    end
  end
end
