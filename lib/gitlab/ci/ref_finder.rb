# frozen_string_literal: true

module Gitlab
  module Ci
    class RefFinder
      def initialize(project)
        @project = project
      end

      def find_by_sha(sha)
        return unless project

        Rails.cache.fetch(['project', project.id, 'ref/containing/sha', sha], expires_in: 5.minutes) do
          break unless project_sha_exists?(sha)

          project_sha_branch_name(sha) || project_sha_tag_name(sha)
        end
      end

      private

      attr_reader :project

      def project_sha_branch_name(sha)
        project.repository.branch_names_contains(sha, limit: 1).first
      end

      def project_sha_tag_name(sha)
        project.repository.tag_names_contains(sha, limit: 1).first
      end

      def project_sha_exists?(sha)
        sha && project.repository_exists? && project.commit(sha)
      end
    end
  end
end
