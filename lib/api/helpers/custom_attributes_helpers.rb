# frozen_string_literal: true

module API
  module Helpers
    module CustomAttributesHelpers
      ALLOWED_FINDERS = %w[find_user find_project find_group].freeze

      def find_resource(attributable_finder, id)
        unless ALLOWED_FINDERS.include?(attributable_finder) && respond_to?(attributable_finder)
          render_api_error!("Invalid finder method: #{attributable_finder}", :bad_request)
        end

        resource = public_send(attributable_finder, id) # rubocop:disable GitlabSecurity/PublicSend -- allowed finders are validated

        not_found! unless resource
        resource
      end
    end
  end
end
