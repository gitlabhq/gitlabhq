# frozen_string_literal: true

module DependencyProxy
  class FindOrCreateBlobService < DependencyProxy::BaseService
    def initialize(group, image, token, blob_sha)
      @group = group
      @image = image
      @token = token
      @blob_sha = blob_sha
    end

    def execute
      from_cache = true
      file_name = @blob_sha.sub('sha256:', '') + '.gz'
      blob = @group.dependency_proxy_blobs.find_or_build(file_name)

      unless blob.persisted?
        from_cache = false
        result = DependencyProxy::DownloadBlobService
          .new(@image, @blob_sha, @token).execute

        if result[:status] == :error
          log_failure(result)

          return error('Failed to download the blob', result[:http_status])
        end

        blob.file = result[:file]
        blob.size = result[:file].size
        blob.save!
      end

      success(blob: blob, from_cache: from_cache)
    end

    private

    def log_failure(result)
      log_error(
        "Dependency proxy: Failed to download the blob." \
        "Blob sha: #{@blob_sha}." \
        "Error message: #{result[:message][0, 100]}" \
        "HTTP status: #{result[:http_status]}"
      )
    end
  end
end
