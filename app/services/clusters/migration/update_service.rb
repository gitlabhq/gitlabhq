# frozen_string_literal: true

module Clusters
  module Migration
    class UpdateService
      attr_reader :cluster, :clusterable, :current_user, :issue_url

      def initialize(cluster, clusterable:, current_user:, issue_url:)
        @cluster = cluster
        @clusterable = clusterable
        @current_user = current_user
        @issue_url = issue_url
      end

      def execute
        return error_response(message: _('Feature disabled')) unless feature_enabled?
        return error_response(message: _('Unauthorized')) unless current_user.can?(:admin_cluster, cluster)
        return error_response(message: s_('ClusterIntegration|No migration found')) unless migration.present?

        issue = extract_issue_from_url(issue_url)
        return error_response(message: s_('ClusterIntegration|Invalid issue URL')) unless issue

        migration.issue = issue

        if migration.save
          ServiceResponse.success(payload: { migration: migration })
        else
          Gitlab::AppLogger.error("Migration issue update failed: #{migration.errors.full_messages.join(', ')}")
          error_response(message: _('Something went wrong'))
        end
      end

      private

      def migration
        @migration ||= cluster.agent_migration
      end

      def extract_issue_from_url(url)
        return unless url.present?

        extractor = Gitlab::ReferenceExtractor.new(migration.agent.project, @current_user)
        extractor.analyze(url)
        extractor.issues&.first
      end

      def feature_enabled?
        Feature.enabled?(:cluster_agent_migrations, clusterable)
      end

      def error_response(message:)
        ServiceResponse.error(message:)
      end
    end
  end
end
