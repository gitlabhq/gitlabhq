# frozen_string_literal: true

module ContainerRegistry
  class GitlabApiClient < BaseClient
    include Gitlab::Utils::StrongMemoize

    JSON_TYPE = 'application/json'
    CANCEL_RESPONSE_STATUS_HEADER = 'status'

    IMPORT_RESPONSES = {
      200 => :already_imported,
      202 => :ok,
      400 => :bad_request,
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

    def self.deduplicated_size(path)
      with_dummy_client(token_config: { type: :nested_repositories_token, path: path&.downcase }) do |client|
        client.repository_details(path, sizing: :self_with_descendants)['size_bytes']
      end
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#compliance-check
    def supports_gitlab_api?
      strong_memoize(:supports_gitlab_api) do
        registry_features = Gitlab::CurrentSettings.container_registry_features || []
        next true if ::Gitlab.com? && registry_features.include?(REGISTRY_GITLAB_V1_API_FEATURE)

        with_token_faraday do |faraday_client|
          response = faraday_client.get('/gitlab/v1/')
          response.success? || response.status == 401
        end
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

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#cancel-repository-import
    def cancel_repository_import(path, force: false)
      response = with_import_token_faraday do |faraday_client|
        faraday_client.delete(import_url_for(path)) do |req|
          req.params['force'] = true if force
        end
      end

      status = IMPORT_RESPONSES.fetch(response.status, :error)
      actual_state = response.body[CANCEL_RESPONSE_STATUS_HEADER]

      { status: status, migration_state: actual_state }
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/api.md#get-repository-import-status
    def import_status(path)
      with_import_token_faraday do |faraday_client|
        response = faraday_client.get(import_url_for(path))

        # Temporary solution for https://gitlab.com/gitlab-org/gitlab/-/issues/356085#solutions
        # this will trigger a `retry_pre_import`
        break 'pre_import_failed' unless response.success?

        body_hash = response_body(response)
        body_hash&.fetch('status') || 'error'
      end
    end

    def repository_details(path, sizing: nil)
      with_token_faraday do |faraday_client|
        req = faraday_client.get("/gitlab/v1/repositories/#{path}/") do |req|
          req.params['size'] = sizing if sizing
        end

        break {} unless req.success?

        response_body(req)
      end
    end

    private

    def start_import_for(path, pre:)
      with_import_token_faraday do |faraday_client|
        faraday_client.put(import_url_for(path)) do |req|
          req.params['import_type'] = pre ? 'pre' : 'final'
        end
      end
    end

    def with_token_faraday
      yield faraday
    end

    def with_import_token_faraday
      yield faraday_with_import_token
    end

    def faraday_with_import_token(timeout_enabled: true)
      @faraday_with_import_token ||= faraday_base(timeout_enabled: timeout_enabled) do |conn|
        # initialize the connection with the :import_token instead of :token
        initialize_connection(conn, @options.merge(token: @options[:import_token]), &method(:configure_connection))
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
