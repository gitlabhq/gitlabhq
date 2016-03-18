module Gitlab
  module GithubImport
    class BaseFormatter
      attr_reader :formatter, :project, :raw_data

      def initialize(project, raw_data)
        @project = project
        @raw_data = raw_data
        @formatter = Gitlab::ImportFormatter.new
      end

      private

      def gl_user_id(github_id)
        User.joins(:identities).
          find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s).
          try(:id)
      end
    end
  end
end
