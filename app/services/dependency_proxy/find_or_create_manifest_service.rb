# frozen_string_literal: true

module DependencyProxy
  class FindOrCreateManifestService < DependencyProxy::BaseService
    def initialize(group, image, tag, token)
      @group = group
      @image = image
      @tag = tag
      @token = token
      @file_name = "#{@image}:#{@tag}.json"
      @manifest = nil
    end

    def execute
      @manifest = @group.dependency_proxy_manifests
                        .find_or_initialize_by_file_name(@file_name)

      head_result = DependencyProxy::HeadManifestService.new(@image, @tag, @token).execute

      return success(manifest: @manifest) if cached_manifest_matches?(head_result)

      pull_new_manifest
      respond
    rescue Timeout::Error, *Gitlab::HTTP::HTTP_ERRORS
      respond
    end

    private

    def pull_new_manifest
      DependencyProxy::PullManifestService.new(@image, @tag, @token).execute_with_manifest do |new_manifest|
        @manifest.update!(
          digest: new_manifest[:digest],
          file: new_manifest[:file],
          size: new_manifest[:file].size
        )
      end
    end

    def cached_manifest_matches?(head_result)
      @manifest && @manifest.digest == head_result[:digest]
    end

    def respond
      if @manifest.persisted?
        success(manifest: @manifest)
      else
        error('Failed to download the manifest from the external registry', 503)
      end
    end
  end
end
