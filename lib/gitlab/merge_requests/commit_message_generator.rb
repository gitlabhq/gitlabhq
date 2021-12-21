# frozen_string_literal: true
module Gitlab
  module MergeRequests
    class CommitMessageGenerator
      def initialize(merge_request:, current_user:)
        @merge_request = merge_request
        @current_user = @merge_request.metrics&.merged_by || @merge_request.merge_user || current_user
      end

      def merge_message
        return unless @merge_request.target_project.merge_commit_template.present?

        replace_placeholders(@merge_request.target_project.merge_commit_template)
      end

      def squash_message
        return unless @merge_request.target_project.squash_commit_template.present?

        replace_placeholders(@merge_request.target_project.squash_commit_template)
      end

      private

      attr_reader :merge_request
      attr_reader :current_user

      PLACEHOLDERS = {
        'source_branch' => ->(merge_request, _) { merge_request.source_branch.to_s },
        'target_branch' => ->(merge_request, _) { merge_request.target_branch.to_s },
        'title' => ->(merge_request, _) { merge_request.title },
        'issues' => ->(merge_request, _) do
          return "" if merge_request.visible_closing_issues_for.blank?

          closes_issues_references = merge_request.visible_closing_issues_for.map do |issue|
            issue.to_reference(merge_request.target_project)
          end
          "Closes #{closes_issues_references.to_sentence}"
        end,
        'description' => ->(merge_request, _) { merge_request.description.presence || '' },
        'reference' => ->(merge_request, _) { merge_request.to_reference(full: true) },
        'first_commit' => -> (merge_request, _) { merge_request.first_commit&.safe_message&.strip.presence || '' },
        'first_multiline_commit' => -> (merge_request, _) { merge_request.first_multiline_commit&.safe_message&.strip.presence || merge_request.title },
        'url' => ->(merge_request, _) { Gitlab::UrlBuilder.build(merge_request) },
        'approved_by' => ->(merge_request, _) { merge_request.approved_by_users.map { |user| "Approved-by: #{user.name} <#{user.commit_email_or_default}>" }.join("\n") },
        'merged_by' => ->(_, user) { "#{user&.name} <#{user&.commit_email_or_default}>" }
      }.freeze

      PLACEHOLDERS_REGEX = Regexp.union(PLACEHOLDERS.keys.map do |key|
        Regexp.new(Regexp.escape(key))
      end).freeze

      BLANK_PLACEHOLDERS_REGEXES = (PLACEHOLDERS.map do |key, value|
        [key, Regexp.new("[\n\r]+%{#{Regexp.escape(key)}}$")]
      end).to_h.freeze

      def replace_placeholders(message)
        # convert CRLF to LF
        message = message.delete("\r")

        # Remove placeholders that correspond to empty values and are the last word in the line
        # along with all whitespace characters preceding them.
        # This allows us to recreate previous default merge commit message behaviour - we skipped new line character
        # before empty description and before closed issues when none were present.
        PLACEHOLDERS.each do |key, value|
          unless value.call(merge_request, current_user).present?
            message = message.gsub(BLANK_PLACEHOLDERS_REGEXES[key], '')
          end
        end

        Gitlab::StringPlaceholderReplacer
          .replace_string_placeholders(message, PLACEHOLDERS_REGEX) do |key|
          PLACEHOLDERS[key].call(merge_request, current_user)
        end
      end
    end
  end
end
