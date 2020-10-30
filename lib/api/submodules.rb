# frozen_string_literal: true

module API
  class Submodules < ::API::Base
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
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects, requirements: Files::FILE_ENDPOINT_REQUIREMENTS do
      desc 'Update existing submodule reference in repository' do
        success Entities::Commit
      end
      params do
        requires :submodule, type: String, desc: 'Url encoded full path to submodule.'
        requires :commit_sha, type: String, desc: 'Commit sha to update the submodule to.'
        requires :branch, type: String, desc: 'Name of the branch to commit into.'
        optional :commit_message, type: String, desc: 'Commit message. If no message is provided a default one will be set.'
      end
      put ":id/repository/submodules/:submodule", requirements: Files::FILE_ENDPOINT_REQUIREMENTS do
        authorize! :push_code, user_project

        submodule_params = declared_params(include_missing: false)

        result = ::Submodules::UpdateService.new(user_project, current_user, commit_params(submodule_params)).execute

        if result[:status] == :success
          commit_detail = user_project.repository.commit(result[:result])
          present commit_detail, with: Entities::CommitDetail
        else
          render_api_error!(result[:message], result[:http_status] || 400)
        end
      end
    end
  end
end
