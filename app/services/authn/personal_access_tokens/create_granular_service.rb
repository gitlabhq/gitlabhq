# frozen_string_literal: true

module Authn
  module PersonalAccessTokens
    class CreateGranularService < BaseService
      include Gitlab::InternalEventsTracking

      def initialize(current_user:, organization:, granular_scopes:, params: {})
        @current_user = current_user
        @organization = organization
        @params = params.dup
        @granular_scopes = granular_scopes
      end

      def execute
        response = nil

        return ServiceResponse.error(message: 'At least one granular scope must be provided') if granular_scopes.empty?

        ::PersonalAccessToken.transaction do
          response = ::PersonalAccessTokens::CreateService.new(
            current_user: current_user, target_user: current_user, params: personal_access_token_params,
            organization_id: organization.id
          ).execute

          raise ActiveRecord::Rollback if response.error?

          token = response.payload[:personal_access_token]

          response = ::Authz::GranularScopeService.new(token).add_granular_scopes(
            granular_scopes
          )

          raise ActiveRecord::Rollback if response.error?

          track_event(token)

          response = ServiceResponse.success(payload: { personal_access_token: token })
        end

        response
      end

      private

      attr_reader :organization, :granular_scopes

      def personal_access_token_params
        default_params = {
          scopes: [::Gitlab::Auth::GRANULAR_SCOPE],
          granular: true
        }

        default_params.merge(params)
      end

      def track_event(token)
        event_property_name_map = {
          instance: 'instance',
          user: 'user',
          all_memberships: 'all_groups_and_projects',
          personal_projects: 'personal_projects',
          selected_memberships: 'groups_and_projects'
        }.stringify_keys

        scopes_by_access = token.granular_scopes.group_by(&:access)

        scope_names = scopes_by_access.keys.map { |access| event_property_name_map[access] }.join(', ')
        permissions_by_access = scopes_by_access.map do |access, scopes|
          permissions = scopes.flat_map(&:permissions).uniq.sort.join(', ')
          "#{event_property_name_map[access]}: #{permissions}"
        end

        track_internal_event(
          'create_pat',
          user: token.user,
          additional_properties: {
            type: 'granular',
            scopes: scope_names,
            permissions: permissions_by_access.join(' | ')
          }
        )
      end
    end
  end
end
