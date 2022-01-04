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

        replace_placeholders(@merge_request.target_project.squash_commit_template, squash: true)
      end

      private

      attr_reader :merge_request
      attr_reader :current_user

      PLACEHOLDERS = {
        'source_branch' => ->(merge_request, _, _) { merge_request.source_branch.to_s },
        'target_branch' => ->(merge_request, _, _) { merge_request.target_branch.to_s },
        'title' => ->(merge_request, _, _) { merge_request.title },
        'issues' => ->(merge_request, _, _) do
          return if merge_request.visible_closing_issues_for.blank?

          closes_issues_references = merge_request.visible_closing_issues_for.map do |issue|
            issue.to_reference(merge_request.target_project)
          end
          "Closes #{closes_issues_references.to_sentence}"
        end,
        'description' => ->(merge_request, _, _) { merge_request.description },
        'reference' => ->(merge_request, _, _) { merge_request.to_reference(full: true) },
        'first_commit' => -> (merge_request, _, _) { merge_request.first_commit&.safe_message&.strip },
        'first_multiline_commit' => -> (merge_request, _, _) { merge_request.first_multiline_commit&.safe_message&.strip.presence || merge_request.title },
        'url' => ->(merge_request, _, _) { Gitlab::UrlBuilder.build(merge_request) },
        'approved_by' => ->(merge_request, _, _) { merge_request.approved_by_users.map { |user| "Approved-by: #{user.name} <#{user.commit_email_or_default}>" }.join("\n") },
        'merged_by' => ->(_, user, _) { "#{user&.name} <#{user&.commit_email_or_default}>" },
        'co_authored_by' => ->(merge_request, merged_by, squash) do
          commit_author = squash ? merge_request.author : merged_by
          merge_request.recent_commits
                       .to_h { |commit| [commit.author_email, commit.author_name] }
                       .except(commit_author&.commit_email_or_default)
                       .map { |author_email, author_name| "Co-authored-by: #{author_name} <#{author_email}>" }
                       .join("\n")
        end
      }.freeze

      PLACEHOLDERS_COMBINED_REGEX = /%{(#{Regexp.union(PLACEHOLDERS.keys)})}/.freeze

      def replace_placeholders(message, squash: false)
        # Convert CRLF to LF.
        message = message.delete("\r")

        used_variables = message.scan(PLACEHOLDERS_COMBINED_REGEX).map { |value| value[0] }.uniq
        values = used_variables.to_h do |variable_name|
          ["%{#{variable_name}}", PLACEHOLDERS[variable_name].call(merge_request, current_user, squash)]
        end
        names_of_empty_variables = values.filter_map { |name, value| name if value.blank? }

        # Remove placeholders that correspond to empty values and are the only word in a line
        # along with all whitespace characters preceding them.
        message = message.gsub(/[\n\r]+#{Regexp.union(names_of_empty_variables)}$/, '') if names_of_empty_variables.present?
        # Substitute all variables with their values.
        message = message.gsub(Regexp.union(values.keys), values) if values.present?

        message
      end
    end
  end
end
