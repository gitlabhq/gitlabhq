# frozen_string_literal: true
module Gitlab
  module MergeRequests
    class MessageGenerator
      def initialize(merge_request:, current_user:)
        @merge_request = merge_request
        @current_user = @merge_request.metrics&.merged_by || @merge_request.merge_user || current_user
      end

      def merge_commit_message
        return unless @merge_request.target_project.merge_commit_template.present?

        replace_placeholders(@merge_request.target_project.merge_commit_template, allowed_placeholders: PLACEHOLDERS)
      end

      def squash_commit_message
        return unless @merge_request.target_project.squash_commit_template.present?

        replace_placeholders(
          @merge_request.target_project.squash_commit_template,
          allowed_placeholders: PLACEHOLDERS,
          squash: true
        )
      end

      def new_mr_description
        return unless @merge_request.description.present?

        replace_placeholders(
          @merge_request.description,
          allowed_placeholders: ALLOWED_NEW_MR_PLACEHOLDERS,
          keep_carriage_return: true
        )
      end

      private

      attr_reader :merge_request, :current_user

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
        'local_reference' => ->(merge_request, _, _) { merge_request.to_reference(full: false) },
        'source_project_id' => ->(merge_request, _, _) { merge_request.source_project.id.to_s },
        'first_commit' => ->(merge_request, _, _) {
          return unless merge_request.persisted? || merge_request.compare_commits.present?

          merge_request.first_commit&.safe_message&.strip
        },
        'first_multiline_commit' => ->(merge_request, _, _) {
          merge_request.first_multiline_commit&.safe_message&.strip.presence || merge_request.title
        },
        'url' => ->(merge_request, _, _) { Gitlab::UrlBuilder.build(merge_request) },
        'reviewed_by' => ->(merge_request, _, _) {
          merge_request.reviewed_by_users
                       .map { |user| "Reviewed-by: #{user.name} <#{user.commit_email_or_default}>" }
                       .join("\n")
        },
        'approved_by' => ->(merge_request, _, _) {
          merge_request.approved_by_users
                       .map { |user| "Approved-by: #{user.name} <#{user.commit_email_or_default}>" }
                       .join("\n")
        },
        'merged_by' => ->(_, user, _) { "#{user&.name} <#{user&.commit_email_or_default}>" },
        'co_authored_by' => ->(merge_request, merged_by, squash) do
          commit_author = squash ? merge_request.author : merged_by
          merge_request.recent_commits
                       .to_h { |commit| [commit.author_email, commit.author_name] }
                       .except(commit_author&.commit_email_or_default)
                       .map { |author_email, author_name| "Co-authored-by: #{author_name} <#{author_email}>" }
                       .join("\n")
        end,
        'merge_request_author' => ->(merge_request, _, _) {
          "#{merge_request.author&.name} <#{merge_request.author&.commit_email_or_default}>"
        },
        'all_commits' => ->(merge_request, _, _) do
          merge_request
            .recent_commits
            .without_merge_commits
            .map do |commit|
              if commit.safe_message&.bytesize&.>(100.kilobytes)
                "* #{commit.title}\n\n-- Skipped commit body exceeding 100KiB in size."
              else
                "* #{commit.safe_message&.strip}"
              end
            end
            .join("\n\n")
        end
      }.freeze

      # A new merge request that is in the process of being created and hasn't
      # been persisted to the database.
      #
      # Limit the placeholders to a subset of the available ones where the
      # placeholders wouldn't make sense in context. Disallowed placeholders
      # will be replaced with an empty string.
      ALLOWED_NEW_MR_PLACEHOLDERS = %w[
        source_branch
        target_branch
        first_commit
        first_multiline_commit
        co_authored_by
        all_commits
      ].freeze

      PLACEHOLDERS_COMBINED_REGEX = /%{(#{Regexp.union(PLACEHOLDERS.keys)})}/

      def replace_placeholders(message, allowed_placeholders: [], squash: false, keep_carriage_return: false)
        # Convert CRLF to LF.
        message = message.delete("\r") unless keep_carriage_return

        used_variables = message.scan(PLACEHOLDERS_COMBINED_REGEX).map { |value| value[0] }.uniq
        values = used_variables.to_h do |variable_name|
          replacement = if allowed_placeholders.include?(variable_name)
                          PLACEHOLDERS[variable_name].call(merge_request, current_user, squash)
                        end

          ["%{#{variable_name}}", replacement]
        end
        names_of_empty_variables = values.filter_map { |name, value| name if value.blank? }

        # Remove lines that contain empty variable placeholder and nothing else.
        if names_of_empty_variables.present?
          # If there is blank line or EOF after it, remove blank line before it as well.
          message = message.gsub(/\n\n#{Regexp.union(names_of_empty_variables)}(\n\n|\Z)/, '\1')
          # Otherwise, remove only the line it is in.
          message = message.gsub(/^#{Regexp.union(names_of_empty_variables)}\n/, '')
        end
        # Substitute all variables with their values.
        message = message.gsub(Regexp.union(values.keys), values) if values.present?

        message
      end
    end
  end
end
