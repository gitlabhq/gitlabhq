module Gitlab
  module Metrics
    class MultiFileEditor
      delegate :total, to: :commit_stats, prefix: :line_changes

      def initialize(project, current_user, commit)
        @project, @current_user, @commit = project, current_user, commit
      end

      def log
        return unless ::License.feature_available?(:ide)

        Rails.logger.info("Web editor usage - #{metric_info}")
      end

      private

      def files_total
        @commit.diffs.size
      end

      def commit_stats
        @commit.stats
      end

      def metric_info
        "ide_usage_project_id: #{@project.id}, ide_usage_user: #{@current_user.id}, ide_usage_line_count: #{line_changes_total}, ide_usage_file_count: #{files_total}"
      end
    end
  end
end
