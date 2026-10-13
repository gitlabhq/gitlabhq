# frozen_string_literal: true

module API
  class ProjectContainerRepositories < ::API::Base
    include PaginationParams
    include ::API::Helpers::ContainerRegistryHelpers

    helpers ::API::Helpers::PackagesHelpers

    REPOSITORY_ENDPOINT_REQUIREMENTS = ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(
      tag_name: ::API::NO_SLASH_URL_PART_REGEX)
    DEFAULT_PAGE_COUNT = 20

    before do
      authorize_read_container_images!
    end

    feature_category :container_registry
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    route_setting :authentication, job_token_allowed: true, job_token_scope: :project
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all registry repositories for a project' do
        detail 'Lists all registry repositories for a specified project. Responses are paginated and return 20 ' \
          'results by default.'
        success Entities::ContainerRegistry::Repository
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        is_array true
        tags %w[container_registry]
      end
      params do
        use :pagination
        optional :tags, type: Boolean, default: false, desc: 'If `true`, includes an array of `tags` in the response.'
        optional :tags_count, type: Boolean, default: false, desc: 'If `true`, includes `tags_count` in the response.'
      end
      route_setting :authorization, permissions: :read_container_repository, boundary_type: :project, skip_job_token_policies: true
      get ':id/registry/repositories' do
        repositories = ContainerRepositoriesFinder.new(
          user: current_user, subject: user_project
        ).execute

        track_package_event('list_repositories', :container, project: user_project, namespace: user_project.namespace)

        present paginate(repositories), with: Entities::ContainerRegistry::Repository, tags: params[:tags], tags_count: params[:tags_count]
      end

      desc 'Delete registry repository' do
        detail 'Deletes a specified repository in the registry. This operation is executed asynchronously and might ' \
          'take some time to execute.'
        success status: :accepted, message: 'Success'
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        is_array true
        tags %w[container_registry]
      end
      params do
        requires :repository_id, type: Integer, desc: 'ID of the container registry repository.'
      end
      route_setting :authorization, permissions: :delete_container_repository, boundary_type: :project, skip_job_token_policies: true
      delete ':id/registry/repositories/:repository_id', requirements: REPOSITORY_ENDPOINT_REQUIREMENTS do
        authorize_admin_container_image!

        if Feature.enabled?(:container_registry_protected_containers_delete, user_project&.root_ancestor) &&
            !current_user.can_admin_all_resources?

          service_response = ContainerRegistry::Protection::CheckRuleExistenceService.for_delete(
            current_user: current_user,
            project: repository.project,
            params: { repository_path: repository.path.to_s }
          ).execute

          forbidden!('Deleting protected container repository forbidden.') if service_response[:protection_rule_exists?]
        end

        repository.delete_scheduled!

        track_package_event('delete_repository', :container, project: user_project, namespace: user_project.namespace)

        status :accepted
      end

      desc 'List all registry repository tags for a project' do
        detail 'Lists all tags for a specified registry repository. Responses are paginated and return 20 results by ' \
          'default.'
        success Entities::ContainerRegistry::Tag
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' },
          { code: 405, message: 'Method Not Allowed' }
        ]
        is_array true
        tags %w[container_registry]
      end
      params do
        requires :repository_id, type: Integer, desc: 'ID of the container registry repository.'
        use :pagination
      end
      route_setting :authorization, permissions: :read_container_repository_tag, boundary_type: :project, skip_job_token_policies: true
      get ':id/registry/repositories/:repository_id/tags', requirements: REPOSITORY_ENDPOINT_REQUIREMENTS do
        authorize_read_container_image!

        paginated_tags =
          if params[:pagination] == 'keyset'
            not_allowed! unless repository.gitlab_api_client.supports_gitlab_api?

            per_page_param = params[:per_page] || DEFAULT_PAGE_COUNT
            sort_param = params[:sort] == 'desc' ? '-name' : 'name'

            response = repository.tags_page(page_size: per_page_param, sort: sort_param, last: params[:last])
            add_next_link_if_next_page_exists(response)

            response[:tags]
          else
            tags = Kaminari.paginate_array(repository.tags)
            paginate(tags)
          end

        track_package_event('list_tags', :container, project: user_project, namespace: user_project.namespace)
        present paginated_tags, with: Entities::ContainerRegistry::Tag
      end

      desc 'Delete multiple registry repository tags' do
        detail 'Deletes multiple registry repository tags based on the specified criteria.'
        success status: :accepted, message: 'Success'
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[container_registry]
      end
      params do
        requires :repository_id, type: Integer, desc: 'ID of the container registry repository.'
        optional :name_regex_delete, type: String, untrusted_regexp: true, desc: '[RE2](https://github.com/google/re2/wiki/Syntax) regular expression of the tag names to delete. Specify `.*` to delete all tags.'
        optional :name_regex, type: String, untrusted_regexp: true, desc: '[RE2](https://github.com/google/re2/wiki/Syntax) regular expression of the tag names to delete. Specify `.*` to delete all tags. Deprecated. Use `name_regex_delete` instead.'
        # require either name_regex (deprecated) or name_regex_delete, it is ok to have both
        at_least_one_of :name_regex, :name_regex_delete
        optional :name_regex_keep, type: String, untrusted_regexp: true, desc: '[RE2](https://github.com/google/re2/wiki/Syntax) regular expression of the tag names to keep. Overrides any matches from `name_regex_delete`. Setting to `.*` results in a no-op.'
        optional :keep_n, type: Integer, desc: 'Number of most recent tags with a matching name to keep.'
        optional :older_than, type: String, desc: 'Delete tags older than this age, such as `1h`, `1d`, or `1month`.'
      end
      route_setting :authorization, permissions: :delete_container_repository_tag, boundary_type: :project, skip_job_token_policies: true
      delete ':id/registry/repositories/:repository_id/tags', requirements: REPOSITORY_ENDPOINT_REQUIREMENTS do
        authorize_admin_container_image!

        message = 'This request has already been made. You can run this at most once an hour for a given container repository'
        render_api_error!(message, 400) unless obtain_new_cleanup_container_lease

        # rubocop:disable CodeReuse/Worker
        CleanupContainerRepositoryWorker.perform_async(current_user.id, repository.id,
          declared_params.except(:repository_id))
        # rubocop:enable CodeReuse/Worker

        track_package_event('delete_tag_bulk', :container, project: user_project, namespace: user_project.namespace)

        status :accepted
      end

      desc 'Retrieve details of a registry repository tag' do
        detail 'Retrieves details of a specified registry repository tag.'
        success Entities::ContainerRegistry::TagDetails
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[container_registry]
      end
      params do
        requires :repository_id, type: Integer, desc: 'ID of the container registry repository.'
        requires :tag_name, type: String, desc: 'Name of the tag.'
      end
      route_setting :authorization, permissions: :read_container_repository_tag, boundary_type: :project, skip_job_token_policies: true
      get ':id/registry/repositories/:repository_id/tags/:tag_name', requirements: REPOSITORY_ENDPOINT_REQUIREMENTS do
        authorize_read_container_image!
        validate_tag!

        present tag, with: Entities::ContainerRegistry::TagDetails
      end

      desc 'Delete a registry repository tag' do
        detail 'Deletes a specified container registry repository tag.'
        success status: :ok, message: 'Success'
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[container_registry]
      end
      params do
        requires :repository_id, type: Integer, desc: 'ID of the container registry repository.'
        requires :tag_name, type: String, desc: 'Name of the tag.'
      end
      route_setting :authorization, permissions: :delete_container_repository_tag, boundary_type: :project, skip_job_token_policies: true
      delete ':id/registry/repositories/:repository_id/tags/:tag_name', requirements: REPOSITORY_ENDPOINT_REQUIREMENTS do
        authorize_destroy_container_image_tag!

        result = ::Projects::ContainerRepository::DeleteTagsService
          .new(repository.project, current_user, tags: [declared_params[:tag_name]])
          .execute(repository)

        if result[:status] == :success
          track_package_event('delete_tag', :container, project: user_project, namespace: user_project.namespace)

          status :ok
        elsif result[:message] == ::Projects::ContainerRepository::Gitlab::DeleteTagsService::PROTECTED_TAGS_ERROR_MESSAGE
          forbidden!(result[:message])
        else
          bad_request!
        end
      end
    end

    helpers do
      def authorize_read_container_images!
        authorize! :read_container_image, user_project
      end

      def authorize_read_container_image!
        authorize! :read_container_image, repository
      end

      def authorize_destroy_container_image_tag!
        authorize! :destroy_container_image_tag, tag
      end

      def authorize_admin_container_image!
        authorize! :admin_container_image, repository
      end

      def obtain_new_cleanup_container_lease
        Gitlab::ExclusiveLease
          .new("container_repository:cleanup_tags:#{repository.id}",
            timeout: 1.hour)
          .try_obtain
      end

      def add_next_link_if_next_page_exists(response)
        next_link_uri = response.dig(:pagination, :next, :uri)
        return unless next_link_uri.present?

        parsed_params = Rack::Utils.parse_query(next_link_uri.query)
        next_params = {
          per_page: parsed_params['n'],
          last: parsed_params['last'],
          sort: parsed_params['sort'] == '-name' ? 'desc' : 'asc'
        }.compact

        Gitlab::Pagination::Keyset::HeaderBuilder
        .new(self)
        .add_next_page_header(next_params)
      end

      def repository
        @repository ||= user_project.container_repositories.find(params[:repository_id])
      end

      def tag
        @tag ||= repository.tag(params[:tag_name])
      end

      def validate_tag!
        not_found!('Tag') unless tag&.valid?
      end
    end
  end
end
