# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class AnalysisService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage

        self.repository_actor = repository
      end

      def check_blobs_generated(base, head, changed_paths)
        request_enum = Enumerator.new do |y|
          changed_paths.each_slice(100).with_index do |paths_subset, i|
            blobs = paths_subset.filter_map do |changed_path|
              # Submodule changes should be ignored as the blob won't exist
              next if changed_path.submodule_change?

              # The Blob won't exist in the base if the file is newly added.
              # We can use the head to get the blob to handle both added or deleted files.
              prefix = changed_path.new_file? ? head : base
              revision = "#{prefix}:#{changed_path.path}"

              Gitaly::CheckBlobsGeneratedRequest::Blob.new(
                revision: encode_binary(revision),
                path: encode_binary(changed_path.path)
              )
            end

            next if blobs.blank?

            params = { blobs: blobs }
            # Repository is only needed for the first request
            params[:repository] = @gitaly_repo if i == 0

            y.yield Gitaly::CheckBlobsGeneratedRequest.new(**params)
          end
        end

        return [] if request_enum.count == 0

        response = gitaly_client_call(
          @repository.storage,
          :analysis_service,
          :check_blobs_generated,
          request_enum,
          timeout: GitalyClient.medium_timeout
        )

        result = []
        response.each do |msg|
          msg.blobs.each do |blob|
            path = blob.revision.split(":", 2).last
            result << { path: path, generated: blob.generated }
          end
        end

        result
      end
    end
  end
end
