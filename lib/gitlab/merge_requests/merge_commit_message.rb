# frozen_string_literal: true
module Gitlab
  module MergeRequests
    class MergeCommitMessage
      def initialize(merge_request:)
        @merge_request = merge_request
      end

      def message
        return unless @merge_request.target_project.merge_commit_template.present?

        message = @merge_request.target_project.merge_commit_template
        message = message.delete("\r")

        # Remove placeholders that correspond to empty values and are the last word in the line
        # along with all whitespace characters preceding them.
        # This allows us to recreate previous default merge commit message behaviour - we skipped new line character
        # before empty description and before closed issues when none were present.
        PLACEHOLDERS.each do |key, value|
          unless value.call(merge_request).present?
            message = message.gsub(BLANK_PLACEHOLDERS_REGEXES[key], '')
          end
        end

        Gitlab::StringPlaceholderReplacer
          .replace_string_placeholders(message, PLACEHOLDERS_REGEX) do |key|
          PLACEHOLDERS[key].call(merge_request)
        end
      end

      private

      attr_reader :merge_request

      PLACEHOLDERS = {
        'source_branch' => ->(merge_request) { merge_request.source_branch.to_s },
        'target_branch' => ->(merge_request) { merge_request.target_branch.to_s },
        'title' => ->(merge_request) { merge_request.title },
        'issues' => ->(merge_request) do
          return "" if merge_request.visible_closing_issues_for.blank?

          closes_issues_references = merge_request.visible_closing_issues_for.map do |issue|
            issue.to_reference(merge_request.target_project)
          end
          "Closes #{closes_issues_references.to_sentence}"
        end,
        'description' => ->(merge_request) { merge_request.description.presence || '' },
        'reference' => ->(merge_request) { merge_request.to_reference(full: true) }
      }.freeze

      PLACEHOLDERS_REGEX = Regexp.union(PLACEHOLDERS.keys.map do |key|
        Regexp.new(Regexp.escape(key))
      end).freeze

      BLANK_PLACEHOLDERS_REGEXES = (PLACEHOLDERS.map do |key, value|
        [key, Regexp.new("[\n\r]+%{#{Regexp.escape(key)}}$")]
      end).to_h.freeze
    end
  end
end
