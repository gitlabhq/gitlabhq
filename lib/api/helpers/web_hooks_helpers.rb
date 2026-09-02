# frozen_string_literal: true

module API
  module Helpers
    module WebHooksHelpers
      extend Grape::API::Helpers

      params :requires_url do
        requires :url, type: String, desc: "The URL to send the request to", documentation: { example: 'http://example.com/hook' }
      end

      params :optional_url do
        optional :url, type: String, desc: "The URL to send the request to"
      end

      params :url_variables do
        optional :url_variables, type: Array, desc: 'URL variables for interpolation' do
          requires :key, type: String, desc: 'Name of the variable', documentation: { example: 'token' }
          requires :value, type: String, desc: 'Value of the variable', documentation: { example: '123' }
        end
      end

      params :custom_headers do
        optional :custom_headers, type: Array, desc: 'Custom headers' do
          requires :key, type: String, desc: 'Name of the header', documentation: { example: 'X-Custom-Header' }
          requires :value, type: String, desc: 'Value of the header', documentation: { example: 'value' }
        end
      end

      def find_hook
        hook_scope.find(params.delete(:hook_id))
      end

      # Overridden by the project and group hook APIs. System hooks have no container.
      def hook_container
        nil
      end

      # Rejecting rather than dropping the attribute keeps this endpoint consistent with
      # the create-flow API: a caller that believes it enabled callbacks must not get a
      # success response when the feature is unavailable. Only enabling is rejected, so a
      # client can PUT back a payload it read from GET. Reads on the declared params, not
      # on params, so endpoints that never declare the attribute are unaffected.
      def validate_duo_flow_callback_param!(hook_params)
        return unless hook_params[:duo_flow_callback_enabled]

        container = hook_container
        return if container && Feature.enabled?(:duo_flow_callback_hooks, container.root_ancestor)

        bad_request!('duo_flow_callback_enabled is not available for this namespace')
      end

      def create_hook_params
        hook_params = declared_params(include_missing: false)
        validate_duo_flow_callback_param!(hook_params)

        url_variables = hook_params.delete(:url_variables)

        if url_variables.present?
          hook_params[:url_variables] = url_variables.to_h { [_1[:key], _1[:value]] }
        end

        custom_headers = hook_params.delete(:custom_headers)

        if custom_headers.present?
          hook_params[:custom_headers] = custom_headers.to_h { [_1[:key], _1[:value]] }
        end

        hook_params
      end

      def update_hook(entity:)
        hook = find_hook
        update_params = update_hook_params(hook)

        hook.assign_attributes(update_params)

        save_hook(hook, entity)
      end

      def update_hook_params(hook)
        update_params = declared_params(include_missing: false)
        validate_duo_flow_callback_param!(update_params)

        url_variables = update_params.delete(:url_variables) || []
        url_variables = url_variables.to_h { [_1[:key], _1[:value]] }
        update_params[:url_variables] = hook.url_variables.merge(url_variables) if url_variables.present?

        custom_headers = update_params.delete(:custom_headers) || []
        custom_headers = custom_headers.to_h { [_1[:key], _1[:value]] }
        update_params[:custom_headers] = hook.custom_headers.merge(custom_headers) if custom_headers.present?

        error!('No parameters provided', :bad_request) if update_params.empty?

        update_params
      end

      def save_hook(hook, entity)
        if hook.save
          present hook, with: entity
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?
          error!("Invalid branch filter given", 422) if hook.errors[:push_events_branch_filter].present?

          if hook.errors[:custom_headers].present?
            error!("Custom headers validation failed: #{hook.errors[:custom_headers].join(', ')}", 422)
          end

          render_validation_error!(hook, 422)
        end
      end
    end
  end
end
