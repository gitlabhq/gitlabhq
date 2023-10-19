# frozen_string_literal: true

module Integrations
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

      def attachment_color
        '#345'
      end

      private

      def humanized_action(short: false)
        action, ref_link, target_link = compose_action_details
        text = [strip_markup(user_combined_name), action, ref_type, ref_link]
        text << target_link unless short
        text.join(' ')
      end

      def message
        humanized_action
      end

      def format(string)
        ::Slack::Messenger::Util::LinkFormatter.format(string)
      end

      def commit_messages
        commits.map { |commit| compose_commit_message(commit) }.join("\n\n")
      end

      def commit_message_attachments
        [{ text: format(commit_messages), color: attachment_color }]
      end

      def compose_commit_message(commit)
        author = commit[:author][:name]
        id = Commit.truncate_sha(commit[:id])
        title = commit[:title]

        url = commit[:url]

        "#{link(id, url)}: #{strip_markup(title)} - #{strip_markup(author)}"
      end

      def new_branch?
        Gitlab::Git.blank_ref?(before)
      end

      def removed_branch?
        Gitlab::Git.blank_ref?(after)
      end

      def ref_url
        if ref_type == 'tag'
          "#{project_url}/-/tags/#{ref}"
        else
          "#{project_url}/-/commits/#{ref}"
        end
      end

      def compare_url
        "#{project_url}/-/compare/#{before}...#{after}"
      end

      def ref_link
        link(ref, ref_url)
      end

      def project_link
        link(project_name, project_url)
      end

      def compare_link
        link('Compare changes', compare_url)
      end

      def compose_action_details
        if new_branch?
          ['pushed new', ref_link, "to #{project_link}"]
        elsif removed_branch?
          ['removed', ref, "from #{project_link}"]
        else
          ['pushed to', ref_link, "of #{project_link} (#{compare_link})"]
        end
      end
    end
  end
end
