# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class ReleaseFormatter < BaseFormatter
      def attributes
        {
          project: project,
          tag: raw_data[:tag_name],
          name: raw_data[:name],
          description: raw_data[:body],
          created_at: raw_data[:created_at],
          # Draft releases will have a null published_at
          released_at: raw_data[:published_at] || Time.current,
          updated_at: raw_data[:created_at]
        }
      end

      def project_association
        :releases
      end

      def find_condition
        { tag: raw_data[:tag_name] }
      end

      def valid?
        !raw_data[:draft] && raw_data[:tag_name].present?
      end
    end
  end
end
