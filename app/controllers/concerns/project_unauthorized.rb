# frozen_string_literal: true

module ProjectUnauthorized
  module ControllerActions
    def self.on_routable_not_found
      ->(routable, full_path) do
        return unless routable.is_a?(Project)

        label = routable.external_authorization_classification_label
        rejection_reason = nil

        unless ::Gitlab::ExternalAuthorization.access_allowed?(current_user, label)
          rejection_reason = ::Gitlab::ExternalAuthorization.rejection_reason(current_user, label)
          rejection_reason ||= _('External authorization denied access to this project')
        end

        access_denied!(rejection_reason) if rejection_reason
      end
    end
  end
end
