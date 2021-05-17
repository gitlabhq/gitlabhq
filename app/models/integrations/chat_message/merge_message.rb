# frozen_string_literal: true

module Integrations
  module ChatMessage
    class MergeMessage < BaseMessage
      attr_reader :merge_request_iid
      attr_reader :source_branch
      attr_reader :target_branch
      attr_reader :action
      attr_reader :state
      attr_reader :title

      def initialize(params)
        super

        obj_attr = params[:object_attributes]
        obj_attr = HashWithIndifferentAccess.new(obj_attr)
        @merge_request_iid = obj_attr[:iid]
        @source_branch = obj_attr[:source_branch]
        @target_branch = obj_attr[:target_branch]
        @action = obj_attr[:action]
        @state = obj_attr[:state]
        @title = format_title(obj_attr[:title])
      end

      def attachments
        []
      end

      def activity
        {
          title: "Merge request #{state_or_action_text} by #{user_combined_name}",
          subtitle: "in #{project_link}",
          text: merge_request_link,
          image: user_avatar
        }
      end

      private

      def format_title(title)
        '*' + title.lines.first.chomp + '*'
      end

      def message
        merge_request_message
      end

      def project_link
        link(project_name, project_url)
      end

      def merge_request_message
        "#{user_combined_name} #{state_or_action_text} merge request #{merge_request_link} in #{project_link}"
      end

      def merge_request_link
        link(merge_request_title, merge_request_url)
      end

      def merge_request_title
        "#{MergeRequest.reference_prefix}#{merge_request_iid} #{title}"
      end

      def merge_request_url
        "#{project_url}/-/merge_requests/#{merge_request_iid}"
      end

      def state_or_action_text
        case action
        when 'approved', 'unapproved'
          action
        when 'approval'
          'added their approval to'
        when 'unapproval'
          'removed their approval from'
        else
          state
        end
      end
    end
  end
end
