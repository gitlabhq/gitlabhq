# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class CommentFormatter < BaseFormatter
      include Import::UsernameMentionRewriter

      attr_writer :author_id

      attr_accessor :gitlab_issuable

      def attributes
        {
          project: project,
          note: note,
          commit_id: raw_data[:commit_id],
          line_code: line_code,
          author_id: author_id,
          type: type,
          created_at: raw_data[:created_at],
          updated_at: raw_data[:updated_at],
          imported_from: imported_from
        }
      end

      def project_association
        :notes
      end

      def create_record
        gitlab_issuable.notes.create!(attributes)
      end

      def contributing_user_formatters
        {
          author_id: author
        }
      end

      private

      def author
        @author ||= UserFormatter.new(client, raw_data[:user], project, source_user_mapper)
      end

      def author_id
        author.gitlab_id || project.creator_id
      end

      def body
        wrap_mentions_in_backticks(raw_data[:body]) || ""
      end

      def line_code
        return unless on_diff?

        parsed_lines = Gitlab::Diff::Parser.new.parse(diff_hunk.lines)
        generate_line_code(parsed_lines.to_a.last)
      end

      def generate_line_code(line)
        Gitlab::Git.diff_line_code(file_path, line.new_pos, line.old_pos)
      end

      def on_diff?
        diff_hunk.present?
      end

      def diff_hunk
        raw_data[:diff_hunk]
      end

      def file_path
        raw_data[:path]
      end

      def note
        if author.gitlab_id
          body
        else
          formatter.author_line(author.login) + body
        end
      end

      def type
        'LegacyDiffNote' if on_diff?
      end
    end
  end
end
