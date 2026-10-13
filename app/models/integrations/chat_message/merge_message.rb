# frozen_string_literal: true

module Integrations
  module ChatMessage
    class MergeMessage < BaseMessage
      attr_reader :merge_request_iid, :source_branch, :target_branch, :action, :state, :title

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
        @reviewers_change = HashWithIndifferentAccess.new(params[:changes] || {})[:reviewers]
      end

      def attachments
        []
      end

      def activity
        {
          title: "Merge request #{state_or_action_text} by #{strip_markup(user_combined_name)}",
          subtitle: "in #{project_link}",
          text: merge_request_link,
          image: user_avatar
        }
      end

      private

      def format_title(title)
        "*#{strip_markup(title.lines.first.chomp)}*"
      end

      def message
        merge_request_message
      end

      def project_link
        link(project_name, project_url)
      end

      def merge_request_message
        "#{strip_markup(user_combined_name)} #{state_or_action_text} merge request #{merge_request_link} in #{project_link}"
      end

      def merge_request_link
        link(merge_request_title, merge_request_url)
      end

      def merge_request_title
        "#{MergeRequest.reference_prefix}#{merge_request_iid} #{strip_markup(title)}"
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
        when 'update'
          reviewers_change_text
        else
          state
        end
      end

      def reviewers_change_text
        return state unless @reviewers_change

        previous = Array(@reviewers_change[:previous])
        current = Array(@reviewers_change[:current])
        requested = difference_by_username(current, previous) | current.select { |reviewer| reviewer[:re_requested] }
        removed = difference_by_username(previous, current)

        if current.empty?
          'removed all reviewers from'
        elsif requested.any?
          "requested a review from #{reviewer_names(requested)} of"
        elsif removed.any?
          "removed #{reviewer_names(removed)} as #{'reviewer'.pluralize(removed.size)} from"
        else
          state
        end
      end

      def difference_by_username(reviewers, other_reviewers)
        other_usernames = other_reviewers.to_set { |reviewer| reviewer[:username] }
        reviewers.reject { |reviewer| other_usernames.include?(reviewer[:username]) }
      end

      def reviewer_names(reviewers)
        reviewers.map { |reviewer| strip_markup("#{reviewer[:name]} (#{reviewer[:username]})") }.to_sentence
      end
    end
  end
end
