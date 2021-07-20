# frozen_string_literal: true

module API
  class ResourceAccessTokens < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :authentication_and_authorization

    %w[project].each do |source_type|
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get list of all access tokens for the specified resource' do
          detail 'This feature was introduced in GitLab 13.9.'
        end
        params do
          requires :id, type: String, desc: "The #{source_type} ID"
        end
        get ":id/access_tokens" do
          resource = find_source(source_type, params[:id])

          next unauthorized! unless current_user.can?(:read_resource_access_tokens, resource)

          tokens = PersonalAccessTokensFinder.new({ user: resource.bots, impersonation: false }).execute.preload_users

          resource.project_members.load
          present paginate(tokens), with: Entities::ResourceAccessToken, project: resource
        end

        desc 'Revoke a resource access token' do
          detail 'This feature was introduced in GitLab 13.9.'
        end
        params do
          requires :id, type: String, desc: "The #{source_type} ID"
          requires :token_id, type: String, desc: "The ID of the token"
        end
        delete ':id/access_tokens/:token_id' do
          resource = find_source(source_type, params[:id])
          token = find_token(resource, params[:token_id])

          if token.nil?
            next not_found!("Could not find #{source_type} access token with token_id: #{params[:token_id]}")
          end

          service = ::ResourceAccessTokens::RevokeService.new(
            current_user,
            resource,
            token
          ).execute

          service.success? ? no_content! : bad_request!(service.message)
        end

        desc 'Create a resource access token' do
          detail 'This feature was introduced in GitLab 13.9.'
        end
        params do
          requires :id, type: String, desc: "The #{source_type} ID"
          requires :name, type: String, desc: "Resource access token name"
          requires :scopes, type: Array[String], desc: "The permissions of the token"
          optional :access_level, type: Integer, desc: "The access level of the token in the project"
          optional :expires_at, type: Date, desc: "The expiration date of the token"
        end
        post ':id/access_tokens' do
          resource = find_source(source_type, params[:id])

          token_response = ::ResourceAccessTokens::CreateService.new(
            current_user,
            resource,
            declared_params
          ).execute

          if token_response.success?
            present token_response.payload[:access_token], with: Entities::ResourceAccessTokenWithToken, project: resource
          else
            bad_request!(token_response.message)
          end
        end
      end
    end

    helpers do
      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def find_token(resource, token_id)
        PersonalAccessTokensFinder.new({ user: resource.bots, impersonation: false }).find_by_id(token_id)
      end
    end
  end
end
