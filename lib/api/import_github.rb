# frozen_string_literal: true

module API
  class ImportGithub < ::API::Base
    before do
      authenticate!
    end

    feature_category :importers
    urgency :low

    rescue_from Octokit::Unauthorized, with: :provider_unauthorized
    rescue_from Gitlab::GithubImport::RateLimitError, with: :too_many_requests

    helpers ::API::Helpers::ImportGithubHelpers

    desc 'Import a repository from GitHub' do
      detail 'Imports a repository from GitHub to GitLab.'
      success code: 201, model: ::ProjectEntity
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 422, message: 'Unprocessable entity' },
        { code: 503, message: 'Service unavailable' }
      ]
      tags ['project_import']
    end
    params do
      requires :personal_access_token, type: String, desc: 'GitHub personal access token.'
      requires :repo_id, type: Integer, desc: 'GitHub repository ID.'
      optional :new_name, type: String, desc: 'Name of the new project. Also used as the new path, so it must not ' \
                                          'start or end with a special character and must not contain ' \
                                          'consecutive special characters.'
      requires :target_namespace, type: String, allow_blank: false, desc: 'Namespace to import the repository into. ' \
                                                                      'Supports subgroups, for example ' \
                                                                      '`/namespace/subgroup`. Must not be blank.'
      optional :github_hostname, type: String, desc: 'Custom GitHub Enterprise hostname. Do not set for GitHub.com. ' \
                                                 'From GitLab 16.5 to GitLab 17.1, you must include the path ' \
                                                 '`/api/v3`.'
      optional :optional_stages, type: Hash,
        desc: 'Additional items to import. For a list of items, see [select additional items to import](https://docs.gitlab.com/user/project/import/github/#select-additional-items-to-import).'
      optional :timeout_strategy, type: String, values: ::ProjectImportData::TIMEOUT_STRATEGIES,
        desc: 'Strategy for handling import timeouts. `optimistic` continues to the next stage of the import. ' \
          '`pessimistic` fails the import immediately. Defaults to `pessimistic`.'
      optional :pagination_limit, type: Integer, desc: 'Number of items retrieved per API request to GitHub. If ' \
                                                   'omitted, defaults to `100`. Use a lower number for large ' \
                                                   'repositories to reduce the risk of GitHub API errors, though ' \
                                                   'this increases migration time.', values: 1..100
    end
    route_setting :authorization, permissions: :create_github_import,
      boundaries: [{ boundary_type: :group, boundary_param: :target_namespace }, { boundary_type: :user }]
    post 'import/github' do
      Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/21041')

      import_params = declared(params, include_parent_namespaces: false).merge(organization_id: Current.organization.id)
      # Continuous sync is only offered to OAuth imports; the API always uses a personal access token.
      import_params[:optional_stages].delete(:continuous_sync)
      import_service = Import::GithubService.new(client, current_user, import_params)
      import_service.request_channel = ::Gitlab::Import::RequestChannel.detect(request)
      result = import_service.execute(access_params, provider)

      if result[:status] == :success
        present ProjectSerializer.new.represent(result[:project], { serializer: :import, warning: result[:warning] })
      else
        status result[:http_status]
        { errors: result[:message] }
      end
    end

    desc 'Cancel a GitHub project import' do
      detail 'Cancels an in-progress import of a GitHub project to GitLab.'
      success code: 200, model: ProjectImportEntity
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 404, message: 'Not found' },
        { code: 503, message: 'Service unavailable' }
      ]
      tags ['project_import']
    end
    params do
      requires :project_id, type: Integer, desc: 'ID of the project whose import to cancel.'
    end
    route_setting :authorization, permissions: :cancel_github_import, boundary_type: :user
    post 'import/github/cancel' do
      project = Project.imported_from(provider.to_s).find(params[:project_id])
      result = Import::Github::CancelProjectImportService.new(project, current_user).execute

      if result[:status] == :success
        status :ok
        present ProjectSerializer.new.represent(project, serializer: :import)
      else
        render_api_error!(result[:message], result[:http_status])
      end
    end

    desc 'Import GitHub gists into GitLab snippets' do
      detail 'Imports personal GitHub gists into GitLab snippets. You can import gists with up to 10 files. ' \
        'GitHub gists with more than 10 files are skipped. You should manually migrate these GitHub gists. ' \
        'If any gists cannot be imported, an email is sent with a list of gists that were not imported.'
      success code: 202
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 422, message: 'Unprocessable Entity' },
        { code: 429, message: 'Too Many Requests' }
      ]
      tags ['imports']
    end
    params do
      requires :personal_access_token, type: String, desc: 'GitHub personal access token.'
    end
    route_setting :authorization, permissions: :create_github_gist_import, boundary_type: :user
    post 'import/github/gists' do
      authorize! :create_snippet

      result = Import::Github::GistsImportService.new(current_user, client, access_params).execute

      if result[:status] == :success
        status 202
      else
        status result[:http_status]
        { errors: result[:message] }
      end
    end
  end
end
