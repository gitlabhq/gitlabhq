# frozen_string_literal: true

module ContainerRegistry
  class GitlabApiClient < BaseClient
    include Gitlab::Utils::StrongMemoize

    JSON_TYPE = 'application/json'

    IMPORT_RESPONSES = {
      200 => :already_imported,
      202 => :ok,
      401 => :unauthorized,
      404 => :not_found,
      409 => :already_being_imported,
      424 => :pre_import_failed,
      425 => :already_being_imported,
      429 => :too_many_imports
    }.freeze

    REGISTRY_GITLAB_V1_API_FEATURE = 'gitlab_v1_api'

    def self.supports_gitlab_api?
      with_dummy_client(return_value_if_disabled: false) do |client|
        client.supports_gitlab_api?
      end
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#compliance-check
    def supports_gitlab_api?
      strong_memoize(:supports_gitlab_api) do
        registry_features = Gitlab::CurrentSettings.container_registry_features || []
        next true if ::Gitlab.com? && registry_features.include?(REGISTRY_GITLAB_V1_API_FEATURE)

        response = faraday.get('/gitlab/v1/')
        response.success? || response.status == 401
      end
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#import-repository
    def pre_import_repository(path)
      response = start_import_for(path, pre: true)
      IMPORT_RESPONSES.fetch(response.status, :error)
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#import-repository
    def import_repository(path)
      response = start_import_for(path, pre: false)
      IMPORT_RESPONSES.fetch(response.status, :error)
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#get-repository-import-status
    def import_status(path)
      body_hash = response_body(faraday.get(import_url_for(path)))
      body_hash['status'] || 'error'
    end

    private

    def start_import_for(path, pre:)
      faraday.put(import_url_for(path)) do |req|
        req.params['pre'] = pre.to_s
      end
    end

    def import_url_for(path)
      "/gitlab/v1/import/#{path}/"
    end

    # overrides the default configuration
    def configure_connection(conn)
      conn.headers['Accept'] = [JSON_TYPE]

      conn.response :json, content_type: JSON_TYPE
    end
  end
end
