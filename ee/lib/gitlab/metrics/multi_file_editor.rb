module Gitlab
  module Metrics
    class MultiFileEditor
      delegate :total, to: :commit_stats, prefix: :line_changes

      def initialize(project, current_user, commit)
        @project, @current_user, @commit = project, current_user, commit
      end

      def record
        return unless ::License.feature_available?(:ide)

        metric = WebIdeMetric.new(metric_data)

        unless metric.save
          Rails.logger.error("Error persisting Web IDE metric: #{metric.as_json} - #{metric.errors.full_messages}")
        end
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

      def metric_data
        {
          project: hashed_project,
          user: hashed_user,
          line_count: line_changes_total,
          file_count: files_total
        }
      end
    end
  end
end
