# frozen_string_literal: true

module Ci
  module Partitions
    class ArchiveService
      include Gitlab::Utils::StrongMemoize

      def initialize(current_partition)
        @current_partition = current_partition
      end

      def execute
        return unless current_partition

        Ci::Partition.id_before(current_partition.id).with_status(:active).each do |partition|
          partition.archive! if archivable?(partition)
        end
      end

      private

      attr_reader :current_partition

      def archivable?(partition)
        return false unless partition.current_until

        archive_builds_older_than.present? && partition.current_until < archive_builds_older_than
      end

      # Partition archival has no per-project context, so the ci_pipeline_archival_setting
      # feature flag is evaluated against :instance here. Per-project evaluations happen
      # at Ci::Pipeline#archived? and Ci::CreateCommitStatusService#first_matching_pipeline.
      def archive_builds_older_than
        return unless ::Feature.enabled?(:ci_pipeline_archival_setting, :instance)

        Gitlab::CurrentSettings.archive_builds_older_than
      end
      strong_memoize_attr :archive_builds_older_than
    end
  end
end
