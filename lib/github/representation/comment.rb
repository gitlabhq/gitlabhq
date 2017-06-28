module Github
  module Representation
    class Comment < Representation::Base
      def note
        raw['body'] || ''
      end

      def author
        @author ||= Github::Representation::User.new(raw['user'], options)
      end

      def commit_id
        raw['commit_id']
      end

      def line_code
        return unless on_diff?

        parsed_lines = Gitlab::Diff::Parser.new.parse(diff_hunk.lines)
        generate_line_code(parsed_lines.to_a.last)
      end

      private

      def generate_line_code(line)
        Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
      end

      def on_diff?
        diff_hunk.present?
      end

      def diff_hunk
        raw['diff_hunk']
      end

      def file_path
        raw['path']
      end
    end
  end
end
