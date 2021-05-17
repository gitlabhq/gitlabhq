# frozen_string_literal: true

module Integrations
  module ChatMessage
    class IssueMessage < BaseMessage
      attr_reader :title
      attr_reader :issue_iid
      attr_reader :issue_url
      attr_reader :action
      attr_reader :state
      attr_reader :description

      def initialize(params)
        super

        obj_attr = params[:object_attributes]
        obj_attr = HashWithIndifferentAccess.new(obj_attr)
        @title = obj_attr[:title]
        @issue_iid = obj_attr[:iid]
        @issue_url = obj_attr[:url]
        @action = obj_attr[:action]
        @state = obj_attr[:state]
        @description = obj_attr[:description] || ''
      end

      def attachments
        return [] unless opened_issue?
        return description if markdown

        description_message
      end

      def activity
        {
          title: "Issue #{state} by #{user_combined_name}",
          subtitle: "in #{project_link}",
          text: issue_link,
          image: user_avatar
        }
      end

      private

      def message
        "[#{project_link}] Issue #{issue_link} #{state} by #{user_combined_name}"
      end

      def opened_issue?
        action == 'open'
      end

      def description_message
        [{
          title: issue_title,
          title_link: issue_url,
          text: format(description),
          color: '#C95823'
        }]
      end

      def project_link
        link(project_name, project_url)
      end

      def issue_link
        link(issue_title, issue_url)
      end

      def issue_title
        "#{Issue.reference_prefix}#{issue_iid} #{title}"
      end
    end
  end
end
