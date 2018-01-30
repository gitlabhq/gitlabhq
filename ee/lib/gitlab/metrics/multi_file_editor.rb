module Gitlab
  module Metrics
    class MultiFileEditor
      delegate :total, to: :commit_stats, prefix: :line_changes

      METRIC_NAME = :multi_file_editor_usage

      def initialize(project, current_user, commit)
        @project, @current_user, @commit = project, current_user, commit
      end

      def record
        ::Gitlab::Metrics.counter(
          METRIC_NAME,
            'Total number of commits using the multi-file web editor',
            metric_labels)
      end

      private

      def files_total
        @commit.diffs.size
      end

      def hashed_project
        Digest::SHA256.hexdigest("#{@project.id}-#{Rails.application.secrets.secret_key_base}")
      end

      def hashed_user
        Digest::SHA256.hexdigest("#{@current_user.id}-#{Rails.application.secrets.secret_key_base}")
      end

      def commit_stats
        @commit.stats
      end

      def metric_labels
        {
            project: hashed_project,
            user: hashed_user,
            line_changes: line_changes_total,
            files_count: files_total
        }
      end
    end
  end
end
