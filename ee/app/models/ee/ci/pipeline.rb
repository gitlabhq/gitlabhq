module EE
  module Ci
    module Pipeline
      extend ActiveSupport::Concern

      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 20,
        size_limit_exceeded: 21
      }.freeze

      included do
        has_one :chat_data, class_name: 'Ci::PipelineChatData'
      end

      def codeclimate_artifact
        @codeclimate_artifact ||= artifacts.codequality.find(&:has_codeclimate_json?)
      end

      def performance_artifact
        @performance_artifact ||= artifacts.performance.find(&:has_performance_json?)
      end

      def sast_artifact
        @sast_artifact ||= artifacts.sast.find(&:has_sast_json?)
      end

      def dependency_scanning_artifact
        @dependency_scanning_artifact ||= artifacts.dependency_scanning.find(&:has_dependency_scanning_json?)
      end

      def sast_container_artifact
        @sast_container_artifact ||= artifacts.sast_container.find(&:has_sast_container_json?)
      end

      def dast_artifact
        @dast_artifact ||= artifacts.dast.find(&:has_dast_json?)
      end

      def initialize_yaml_processor
        ::Gitlab::Ci::YamlProcessor.new(ci_yaml_file, { project: project, sha: sha })
      end

      def has_sast_data?
        sast_artifact&.success?
      end

      def has_dependency_scanning_data?
        dependency_scanning_artifact&.success?
      end

      def has_sast_container_data?
        sast_container_artifact&.success?
      end

      def has_dast_data?
        dast_artifact&.success?
      end

      def has_performance_data?
        performance_artifact&.success?
      end

      def has_codeclimate_data?
        codeclimate_artifact&.success?
      end

      def expose_sast_data?
        project.feature_available?(:sast) &&
          has_sast_data?
      end

      def expose_dependency_scanning_data?
        project.feature_available?(:dependency_scanning) &&
          has_dependency_scanning_data?
      end

      def expose_sast_container_data?
        project.feature_available?(:sast_container) &&
          has_sast_container_data?
      end

      def expose_dast_data?
        project.feature_available?(:dast) &&
          has_dast_data?
      end

      def expose_performance_data?
        project.feature_available?(:merge_request_performance_metrics) &&
          has_performance_data?
      end

      def expose_codeclimate_data?
        has_codeclimate_data?
      end
    end
  end
end
