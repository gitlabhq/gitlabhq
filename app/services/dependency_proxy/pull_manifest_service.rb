# frozen_string_literal: true

module DependencyProxy
  class PullManifestService < DependencyProxy::BaseService
    def initialize(image, tag, token)
      @image = image
      @tag = tag
      @token = token
    end

    def execute_with_manifest
      raise ArgumentError, 'Block must be provided' unless block_given?

      response = Gitlab::HTTP.get(manifest_url, headers: auth_headers.merge(Accept: ::ContainerRegistry::Client::ACCEPTED_TYPES.join(',')))

      if response.success?
        file = Tempfile.new

        begin
          file.write(response)
          file.flush

          yield(success(file: file, digest: response.headers['docker-content-digest'], content_type: response.headers['content-type']))
        ensure
          file.close
          file.unlink
        end
      else
        yield(error(response.body, response.code))
      end
    rescue Timeout::Error => exception
      error(exception.message, 599)
    end

    private

    def manifest_url
      registry.manifest_url(@image, @tag)
    end
  end
end
