module Gitlab
  module GithubImport
    class Comment
      attr_reader :project, :raw_data

      def initialize(project, raw_data)
        @project = project
        @raw_data = raw_data
        @formatter = Gitlab::ImportFormatter.new
      end

      def attributes
        {
          project: project,
          note: note,
          commit_id: raw_data.commit_id,
          line_code: line_code,
          author_id: author_id,
          created_at: raw_data.created_at,
          updated_at: raw_data.updated_at
        }
      end

      private

      def author
        raw_data.user.login
      end

      def author_id
        gl_user_id(raw_data.user.id) || project.creator_id
      end

      def body
        raw_data.body || ""
      end

      def line_code
        if on_diff?
          Gitlab::Diff::LineCode.generate(raw_data.path, raw_data.position, 0)
        end
      end

      def on_diff?
        raw_data.path && raw_data.position
      end

      def note
        @formatter.author_line(author) + body
      end

      def gl_user_id(github_id)
        User.joins(:identities).
          find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s).
          try(:id)
      end
    end
  end
end
