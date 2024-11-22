# frozen_string_literal: true

module API
  class Submodules < ::API::Base
    SUBMODULE_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(submodule: API::NO_SLASH_URL_PART_REGEX)

    before { authenticate! }

    feature_category :source_code_management

    helpers do
      def commit_params(attrs)
        {
          submodule: attrs[:submodule],
          commit_sha: attrs[:commit_sha],
          branch_name: attrs[:branch],
          commit_message: attrs[:commit_message]
        }
      end
    end

    params do
      requires :id,
        type: String,
        desc: 'The ID or URL-encoded path of a project',
        documentation: { example: 'gitlab-org/gitlab' }
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Update existing submodule reference in repository' do
        success code: 200, model: Entities::CommitDetail
        failure [
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' },
          { code: 400, message: 'The repository is empty' }
        ]
      end
      params do
        requires :submodule,
          type: String,
          desc: 'Url encoded full path to submodule.',
          documentation: { example: 'gitlab-org/gitlab-shell' }
        requires :commit_sha,
          type: String,
          desc: 'Commit sha to update the submodule to.',
          documentation: { example: 'ed899a2f4b50b4370feeea94676502b42383c746' }
        requires :branch, type: String, desc: 'Name of the branch to commit into.', documentation: { example: 'main' }
        optional :commit_message,
          type: String,
          desc: 'Commit message. If no message is provided a default one will be set.',
          documentation: { example: 'Commit message' }
      end
      put ":id/repository/submodules/:submodule", requirements: SUBMODULE_ENDPOINT_REQUIREMENTS do
        authorize! :push_code, user_project

        submodule_params = declared_params(include_missing: false)

        result = ::Submodules::UpdateService.new(user_project, current_user, commit_params(submodule_params)).execute

        if result[:status] == :success
          commit_detail = user_project.repository.commit(result[:result])
          present commit_detail, with: Entities::CommitDetail, current_user: current_user
        else
          render_api_error!(result[:message], result[:http_status] || 400)
        end
      end
    end
  end
end
