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
                        .active
                        .find_by_file_name_or_digest(file_name: @file_name, digest: @tag)

      head_result = DependencyProxy::HeadManifestService.new(@image, @tag, @token).execute

      return respond if cached_manifest_matches?(head_result)

      if Feature.enabled?(:dependency_proxy_manifest_workhorse, @group, default_enabled: :yaml)
        success(manifest: nil, from_cache: false)
      else
        pull_new_manifest
        respond(from_cache: false)
      end
    rescue Timeout::Error, *Gitlab::HTTP::HTTP_ERRORS
      respond
    end

    private

    def pull_new_manifest
      DependencyProxy::PullManifestService.new(@image, @tag, @token).execute_with_manifest do |new_manifest|
        params = {
          file_name: @file_name,
          content_type: new_manifest[:content_type],
          digest: new_manifest[:digest],
          file: new_manifest[:file],
          size: new_manifest[:file].size
        }

        if @manifest
          @manifest.update!(params)
        else
          @manifest = @group.dependency_proxy_manifests.create!(params)
        end
      end
    end

    def cached_manifest_matches?(head_result)
      return false if head_result[:status] == :error

      @manifest && @manifest.digest == head_result[:digest] && @manifest.content_type == head_result[:content_type]
    end

    def respond(from_cache: true)
      if @manifest
        @manifest.read!

        success(manifest: @manifest, from_cache: from_cache)
      else
        error('Failed to download the manifest from the external registry', 503)
      end
    end
  end
end
