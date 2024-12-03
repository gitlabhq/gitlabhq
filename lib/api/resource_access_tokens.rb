# frozen_string_literal: true

module API
  class ResourceAccessTokens < ::API::Base
    include PaginationParams

    ALLOWED_RESOURCE_ACCESS_LEVELS = Gitlab::Access.options_with_owner.freeze

    before { authenticate! }

    feature_category :system_access

    %w[project group].each do |source_type|
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get list of all access tokens for the specified resource' do
          detail 'This feature was introduced in GitLab 13.9.'
          is_array true
          tags ["#{source_type}_access_tokens"]
          success Entities::ResourceAccessToken
        end
        params do
          requires :id, types: [String, Integer], desc: "ID or URL-encoded path of the #{source_type}"
          optional :state, type: String, desc: 'Filter tokens which are either active or inactive',
            values: %w[active inactive], documentation: { example: 'active' }
        end
        get ":id/access_tokens" do
          resource = find_source(source_type, params[:id])

          next unauthorized! unless current_user.can?(:read_resource_access_tokens, resource)

          tokens = PersonalAccessTokensFinder.new({ user: resource.bots, impersonation: false, state: params[:state] }).execute.preload_users

          resource.members.load
          present paginate(tokens), with: Entities::ResourceAccessToken, resource: resource
        end

        desc 'Get an access token for the specified resource by ID' do
          detail 'This feature was introduced in GitLab 14.10.'
          tags ["#{source_type}_access_tokens"]
          success Entities::ResourceAccessToken
        end
        params do
          requires :id, types: [String, Integer], desc: "ID or URL-encoded path of the #{source_type}"
          requires :token_id, type: String, desc: "The ID of the token"
        end
        get ":id/access_tokens/:token_id" do
          resource = find_source(source_type, params[:id])

          next unauthorized! unless current_user.can?(:read_resource_access_tokens, resource)

          token = find_token(resource, params[:token_id])

          if token.nil?
            next not_found!("Could not find #{source_type} access token with token_id: #{params[:token_id]}")
          end

          resource.members.load
          present token, with: Entities::ResourceAccessToken, resource: resource
        end

        desc 'Revoke a resource access token' do
          detail 'This feature was introduced in GitLab 13.9.'
          tags ["#{source_type}_access_tokens"]
          success code: 204
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 404, message: 'Not found' }
          ]
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
          tags ["#{source_type}_access_tokens"]
          success Entities::ResourceAccessTokenWithToken
        end
        params do
          requires :id,
            type: String,
            desc: "The #{source_type} ID",
            documentation: { example: 2 }
          requires :name,
            type: String,
            desc: "Resource access token name",
            documentation: { example: 'test' }
          requires :scopes,
            type: Array[String],
            values: ::Gitlab::Auth.resource_bot_scopes.map(&:to_s),
            desc: "The permissions of the token",
            documentation: { example: %w[api read_repository] }
          requires :expires_at,
            type: Date,
            desc: "The expiration date of the token",
            default: PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now,
            documentation: { example: '"2021-01-31' }
          optional :description,
            type: String,
            desc: "Resource access token description",
            documentation: { example: 'test description' }
          optional :access_level,
            type: Integer,
            values: ALLOWED_RESOURCE_ACCESS_LEVELS.values,
            default: Gitlab::Access::MAINTAINER,
            desc: "The access level of the token in the #{source_type}",
            documentation: { example: 40 }
        end
        post ':id/access_tokens' do
          resource = find_source(source_type, params[:id])

          token_response = ::ResourceAccessTokens::CreateService.new(
            current_user,
            resource,
            declared_params
          ).execute

          if token_response.success?
            present token_response.payload[:access_token], with: Entities::ResourceAccessTokenWithToken, resource: resource
          else
            bad_request!(token_response.message)
          end
        end

        desc 'Rotate a resource access token' do
          detail 'This feature was introduced in GitLab 16.0.'
          tags ["#{source_type}_access_tokens"]
          success Entities::ResourceAccessTokenWithToken
        end
        params do
          requires :id, type: String, desc: "The #{source_type} ID"
          requires :token_id, type: String, desc: "The ID of the token"
          optional :expires_at,
            type: Date,
            desc: "The expiration date of the token",
            documentation: { example: '2021-01-31' }
        end
        post ':id/access_tokens/:token_id/rotate' do
          resource = find_source(source_type, params[:id])

          resource_accessible = Ability.allowed?(current_user, :manage_resource_access_tokens, resource)
          token = find_token(resource, params[:token_id]) if resource_accessible

          if token
            response = if source_type == "project"
                         ::ProjectAccessTokens::RotateService.new(
                           current_user, token, resource, declared_params).execute
                       elsif source_type == "group"
                         ::GroupAccessTokens::RotateService.new(
                           current_user, token, resource, declared_params).execute
                       else
                         ::PersonalAccessTokens::RotateService.new(
                           current_user, token, nil, declared_params).execute
                       end

            if response.success?
              status :ok

              new_token = response.payload[:personal_access_token]
              present new_token, with: Entities::ResourceAccessTokenWithToken, resource: resource
            else
              bad_request!(response.message)
            end
          else
            # Only admins should be informed if the token doesn't exist
            current_user.can_admin_all_resources? ? not_found! : unauthorized!
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
