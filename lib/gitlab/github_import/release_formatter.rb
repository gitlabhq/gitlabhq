module Gitlab
  module GithubImport
    class ReleaseFormatter < BaseFormatter
      def attributes
        {
          project: project,
          tag: raw_data.tag_name,
          description: raw_data.body,
          created_at: raw_data.created_at,
          updated_at: raw_data.created_at
        }
      end

      def klass
        Release
      end

      def valid?
        !raw_data.draft
      end
    end
  end
end
