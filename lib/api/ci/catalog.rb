# frozen_string_literal: true

module API
  module Ci
    class Catalog < ::API::Base
      feature_category :pipeline_composition

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Publish a new component project release as version to the CI/CD catalog' do
          detail 'Publishes a release of a catalog resource as version to the CI/CD catalog.'
          named 'publish_version'
          success Entities::Ci::Catalog::Resources::Version
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
        end
        params do
          requires :version, type: String, desc: 'The version of the catalog resource / tag of the release to publish'
          requires :metadata, type: Hash, desc: 'The metadata for the release'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :admin_releases
        # Note: This endpoint should only be used by `release-cli` and should be authenticated with a job token.
        # For this reason, we should not document the endpoint in the API docs.
        post ':id/catalog/publish' do
          release = user_project.releases.find_by_tag!(params[:version])
          authorize! :publish_catalog_version, release

          result = ::Ci::Catalog::Resources::ReleaseService.new(release, current_user, params[:metadata]).execute

          if result.success?
            present result.payload[:version], with: Entities::Ci::Catalog::Resources::Version
          else
            render_api_error!(result.message, 422)
          end
        end
      end
    end
  end
end
