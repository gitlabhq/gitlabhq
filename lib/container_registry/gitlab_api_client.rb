# frozen_string_literal: true

module ContainerRegistry
  class GitlabApiClient < BaseClient
    include Gitlab::Utils::StrongMemoize

    JSON_TYPE = 'application/json'
    CANCEL_RESPONSE_STATUS_HEADER = 'status'
    GITLAB_REPOSITORIES_PATH = '/gitlab/v1/repositories'

    RENAME_RESPONSES = {
      202 => :accepted,
      204 => :ok,
      400 => :bad_request,
      401 => :unauthorized,
      404 => :not_found,
      409 => :name_taken,
      422 => :too_many_subrepositories
    }.freeze

    REGISTRY_GITLAB_V1_API_FEATURE = 'gitlab_v1_api'

    MAX_TAGS_PAGE_SIZE = 1000
    MAX_REPOSITORIES_PAGE_SIZE = 1000
    PAGE_SIZE = 1

    UnsuccessfulResponseError = Class.new(StandardError)

    def self.supports_gitlab_api?
      with_dummy_client(return_value_if_disabled: false) do |client|
        client.supports_gitlab_api?
      end
    end

    def self.deduplicated_size(path)
      downcased_path = path&.downcase
      with_dummy_client(token_config: { type: :nested_repositories_token, path: downcased_path }) do |client|
        client.repository_details(downcased_path, sizing: :self_with_descendants)['size_bytes']
      end
    end

    def self.one_project_with_container_registry_tag(path)
      downcased_path = path&.downcase
      with_dummy_client(token_config: { type: :nested_repositories_token, path: downcased_path }) do |client|
        page = client.sub_repositories_with_tag(downcased_path, page_size: PAGE_SIZE)
        details = page[:response_body]&.first

        break unless details

        path = ContainerRegistry::Path.new(details["path"])

        break unless path.valid?

        ContainerRepository.find_by_path(path)&.project
      end
    end

    def self.rename_base_repository_path(path, name:, dry_run: false)
      raise ArgumentError, 'incomplete parameters given' unless path.present? && name.present?

      downcased_path = path.downcase

      with_dummy_client(token_config: { type: :push_pull_nested_repositories_token, path: downcased_path }) do |client|
        client.rename_base_repository_path(downcased_path, name: name.downcase, dry_run: dry_run)
      end
    end

    def self.move_repository_to_namespace(path, namespace:, dry_run: false)
      raise ArgumentError, 'incomplete parameters given' unless path.present? && namespace.present?

      downcased_path = path.downcase
      downcased_namespace = namespace.downcase

      token_config = {
        type: :push_pull_move_repositories_access_token,
        path: downcased_path,
        new_path: downcased_namespace
      }

      with_dummy_client(token_config: token_config) do |client|
        client.move_repository_to_namespace(downcased_path, namespace: downcased_namespace, dry_run: dry_run)
      end
    end

    def self.each_sub_repositories_with_tag_page(path:, page_size: 100, &block)
      raise ArgumentError, 'block not given' unless block

      # dummy uri to initialize the loop
      next_page_uri = URI('')
      page_count = 0
      downcased_path = path&.downcase

      with_dummy_client(token_config: { type: :nested_repositories_token, path: downcased_path }) do |client|
        while next_page_uri
          last = Rack::Utils.parse_nested_query(next_page_uri.query)['last']
          current_page = client.sub_repositories_with_tag(downcased_path, page_size: page_size, last: last)

          if current_page&.key?(:response_body)
            yield (current_page[:response_body] || [])
            next_page_uri = current_page.dig(:pagination, :next, :uri)
          else
            # no current page. Break the loop
            next_page_uri = nil
          end

          page_count += 1

          raise 'too many pages requested' if page_count >= MAX_REPOSITORIES_PAGE_SIZE
        end
      end
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md#compliance-check
    def supports_gitlab_api?
      strong_memoize(:supports_gitlab_api) do
        registry_features = Gitlab::CurrentSettings.container_registry_features || []
        next true if ::Gitlab.com_except_jh? && registry_features.include?(REGISTRY_GITLAB_V1_API_FEATURE)

        with_token_faraday do |faraday_client|
          response = faraday_client.get('/gitlab/v1/')
          response.success? || response.status == 401
        end
      end
    rescue ::Faraday::Error
      false
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md#get-repository-details
    def repository_details(path, sizing: nil)
      with_token_faraday do |faraday_client|
        req = faraday_client.get("#{GITLAB_REPOSITORIES_PATH}/#{path}/") do |req|
          req.params['size'] = sizing if sizing
        end

        break {} unless req.success?

        response_body(req)
      end
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md#list-repository-tags
    def tags(path, page_size: 100, last: nil, before: nil, name: nil, sort: nil, referrers: nil, referrer_type: nil)
      limited_page_size = [page_size, MAX_TAGS_PAGE_SIZE].min
      with_token_faraday do |faraday_client|
        url = "#{GITLAB_REPOSITORIES_PATH}/#{path}/tags/list/"
        response = faraday_client.get(url) do |req|
          req.params['n'] = limited_page_size
          req.params['last'] = last if last
          req.params['before'] = before if before
          req.params['name'] = name if name.present?
          req.params['sort'] = sort if sort
          req.params['referrers'] = 'true' if referrers
          req.params['referrer_type'] = referrer_type if referrer_type
        end

        unless response.success?
          Gitlab::ErrorTracking.log_exception(
            UnsuccessfulResponseError.new,
            class: self.class.name,
            url: url,
            status_code: response.status
          )

          break {}
        end

        link_parser = Gitlab::Utils::LinkHeaderParser.new(response.headers['link'])

        {
          pagination: link_parser.parse,
          response_body: response_body(response)
        }
      end
    end

    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md#list-sub-repositories
    def sub_repositories_with_tag(path, page_size: 100, last: nil)
      limited_page_size = [page_size, MAX_REPOSITORIES_PAGE_SIZE].min

      with_token_faraday do |faraday_client|
        url = "/gitlab/v1/repository-paths/#{path}/repositories/list/"
        response = faraday_client.get(url) do |req|
          req.params['n'] = limited_page_size
          req.params['last'] = last if last
        end

        unless response.success?
          Gitlab::ErrorTracking.log_exception(
            UnsuccessfulResponseError.new,
            class: self.class.name,
            url: url,
            status_code: response.status
          )

          break {}
        end

        link_parser = Gitlab::Utils::LinkHeaderParser.new(response.headers['link'])

        {
          pagination: link_parser.parse,
          response_body: response_body(response)
        }
      end
    end

    # Given a path 'group/subgroup/project' and name 'newname',
    # with a successful rename, it will be 'group/subgroup/newname'
    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md#rename-base-repository
    def rename_base_repository_path(path, name:, dry_run: false)
      patch_repository(path, { name: name }, dry_run: dry_run)
    end

    # Given a path 'group/subgroup/project' and a namespace 'group/subgroup_2'
    # with a successful move, it will be 'group/subgroup_2/project'
    # https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/api.md#renamemove-origin-repository
    def move_repository_to_namespace(path, namespace:, dry_run: false)
      patch_repository(path, { namespace: namespace }, dry_run: dry_run)
    end

    private

    def patch_repository(path, body, dry_run: false)
      with_token_faraday do |faraday_client|
        url = "#{GITLAB_REPOSITORIES_PATH}/#{path}/"
        response = faraday_client.patch(url) do |req|
          req.params['dry_run'] = dry_run
          req.body = body
        end

        unless response.success?
          Gitlab::ErrorTracking.log_exception(
            UnsuccessfulResponseError.new,
            class: self.class.name,
            url: url,
            status_code: response.status
          )
        end

        RENAME_RESPONSES.fetch(response.status, :error)
      end
    end

    def with_token_faraday
      yield faraday
    end

    # overrides the default configuration
    def configure_connection(conn)
      conn.headers['Accept'] = [JSON_TYPE]

      conn.response :json, content_type: JSON_TYPE
    end
  end
end

ContainerRegistry::GitlabApiClient.prepend_mod
