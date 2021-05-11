# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanJobArtifactFilesBatch
      BatchFull = Class.new(StandardError)

      class ArtifactFile
        attr_accessor :path

        def initialize(path)
          @path = path
        end

        def artifact_id
          path.split('/').last.to_i
        end
      end

      include Gitlab::Utils::StrongMemoize

      attr_reader :batch_size, :dry_run
      attr_accessor :artifact_files

      def initialize(batch_size:, dry_run: true, logger: Gitlab::AppLogger)
        @batch_size = batch_size
        @dry_run = dry_run
        @logger = logger
        @artifact_files = []
      end

      def clean!
        return if artifact_files.empty?

        lost_and_found.each do |artifact|
          clean_one!(artifact)
        end
      end

      def full?
        artifact_files.count >= batch_size
      end

      def <<(artifact_path)
        raise BatchFull, "Batch full! Already contains #{artifact_files.count} artifacts" if full?

        artifact_files << ArtifactFile.new(artifact_path)
      end

      def lost_and_found
        strong_memoize(:lost_and_found) do
          artifact_file_ids = artifact_files.map(&:artifact_id)
          existing_artifact_ids = ::Ci::JobArtifact.id_in(artifact_file_ids).pluck_primary_key

          artifact_files.reject { |artifact| existing_artifact_ids.include?(artifact.artifact_id) }
        end
      end

      private

      def clean_one!(artifact_file)
        log_debug("Found orphan job artifact file @ #{artifact_file.path}")

        remove_file!(artifact_file) unless dry_run
      end

      def remove_file!(artifact_file)
        FileUtils.rm_rf(artifact_file.path)
      end

      def log_info(msg, params = {})
        @logger.info("#{'[DRY RUN]' if dry_run} #{msg}")
      end

      def log_debug(msg, params = {})
        @logger.debug(msg)
      end
    end
  end
end

Gitlab::Cleanup::OrphanJobArtifactFilesBatch.prepend_mod_with('Gitlab::Cleanup::OrphanJobArtifactFilesBatch')
