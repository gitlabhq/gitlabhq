module Gitlab
  module LegacyGithubImport
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

      def project_association
        :releases
      end

      def find_condition
        { tag: raw_data.tag_name }
      end

      def valid?
        !raw_data.draft
      end
    end
  end
end
