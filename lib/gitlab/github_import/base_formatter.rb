module Gitlab
  module GithubImport
    class BaseFormatter
      attr_reader :formatter, :project, :raw_data

      def initialize(project, raw_data)
        @project = project
        @raw_data = raw_data
        @formatter = Gitlab::ImportFormatter.new
      end

      def create!
        project.send(project_association).find_or_create_by!(find_condition) do |record|
          record.attributes = attributes
        end
      end

      private

      def gitlab_user_id(github_id)
        User.joins(:identities).
          find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s).
          try(:id)
      end

      def gitlab_author_id
        return @gitlab_author_id if defined?(@gitlab_author_id)
        @gitlab_author_id = gitlab_user_id(raw_data.user.id)
      end
    end
  end
end
