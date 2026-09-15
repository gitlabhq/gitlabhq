# frozen_string_literal: true

module API
  module Internal
    # Internal API used by the org-mover control plane to drive an
    # organization's maintenance lifecycle. Authenticated by the gitlab-shell
    # JWT (authenticate_by_gitlab_shell_token!), so there is no per-user
    # authorization. Gated per organization by the `org_mover_maintenance_api`
    # feature flag so a valid token can only act on an organization an operator
    # has explicitly enabled for a move. The flag must never be enabled globally,
    # and must be disabled once the move completes: it does not expire on its own,
    # and while it is on the organization can be taken into maintenance.
    class OrgMover < ::API::Base
      # This reuses the shared gitlab-shell secret; a dedicated secret and
      # audience are tracked in
      # https://gitlab.com/gitlab-org/gitlab/-/issues/627692.
      before do
        authenticate_by_gitlab_shell_token!
      end

      feature_category :organization

      helpers do
        def find_org!
          organization = ::Organizations::Organization.find_by_id(params[:organization_id])

          not_found!('Organization') unless organization
          not_found!('Organization') unless Feature.enabled?(:org_mover_maintenance_api, organization)

          organization
        end

        # Runs the transition service and maps its ServiceResponse. Services are
        # idempotent (returning success when already in the target state). A
        # temporary failure (e.g. not drained yet) returns 409 so the client
        # retries; an invalid transition returns 422, which the client treats as
        # permanent (non-retryable).
        def transition!
          response = yield(find_org!)

          if response.success?
            no_content!
          elsif response.reason == :not_ready
            render_api_error!(response.message, 409)
          else
            render_api_error!(response.message, 422)
          end
        end
      end

      namespace 'internal/org_mover' do
        desc "Report an organization's current lifecycle state" do
          detail 'Returns the organization\'s current maintenance lifecycle state.'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[organizations]
        end
        params do
          requires :organization_id, type: Integer, desc: 'The ID of the organization'
        end
        route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
        get 'maintenance_state' do
          organization = find_org!

          { state: organization.state_name }
        end

        desc 'Report cutover readiness for an organization' do
          detail 'Reports whether an organization is drained and safe to enter maintenance.'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[organizations]
        end
        params do
          requires :organization_id, type: Integer, desc: 'The ID of the organization'
        end
        route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
        get 'maintenance_readiness' do
          organization = find_org!
          readiness = ::Gitlab::Organizations::MaintenanceReadiness.new(organization)

          { ready: readiness.ready? }
        end

        desc 'Start maintenance on an organization (active -> maintenance_initialization)' do
          detail 'Begins the maintenance transition for an organization.'
          success code: 204
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags %w[organizations]
        end
        params do
          requires :organization_id, type: Integer, desc: 'The ID of the organization'
          requires :maintenance_reason, type: String, values: ::Organizations::Stateful::MAINTENANCE_REASONS,
            desc: 'The reason for entering maintenance'
        end
        route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
        post 'start_maintenance' do
          transition! do |org|
            ::Organizations::StartMaintenanceService
              .new(org, maintenance_reason: params[:maintenance_reason])
              .execute
          end
        end

        desc 'Confirm maintenance on an organization (maintenance_initialization -> maintenance)' do
          detail 'Completes the maintenance transition once the organization is drained.'
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' },
            { code: 409, message: 'Conflict' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags %w[organizations]
        end
        params do
          requires :organization_id, type: Integer, desc: 'The ID of the organization'
        end
        route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
        post 'confirm_maintenance' do
          transition! do |org|
            ::Organizations::ConfirmMaintenanceService.new(org).execute
          end
        end

        desc 'Cancel maintenance on an organization (maintenance_initialization -> active)' do
          detail 'Aborts maintenance initialization before the organization reaches the ' \
            'maintenance state, returning it to active.'
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags %w[organizations]
        end
        params do
          requires :organization_id, type: Integer, desc: 'The ID of the organization'
        end
        route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
        post 'cancel_maintenance' do
          transition! do |org|
            ::Organizations::CancelMaintenanceService.new(org).execute
          end
        end

        desc 'Exit maintenance on an organization (maintenance -> active)' do
          detail 'Returns an organization from maintenance to active.'
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags %w[organizations]
        end
        params do
          requires :organization_id, type: Integer, desc: 'The ID of the organization'
        end
        route_setting :authorization, skip_granular_token_authorization: :gitlab_shell_token_auth
        post 'exit_maintenance' do
          transition! do |org|
            ::Organizations::ExitMaintenanceService.new(org).execute
          end
        end
      end
    end
  end
end
