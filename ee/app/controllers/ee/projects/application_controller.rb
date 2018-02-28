module EE
  module Projects
    module ApplicationController
      extend ::Gitlab::Utils::Override

      override :handle_not_found_or_authorized
      def handle_not_found_or_authorized(project)
        return super unless project

        label = project.external_authorization_classification_label
        rejection_reason = nil

        unless EE::Gitlab::ExternalAuthorization.access_allowed?(current_user, label)
          rejection_reason = EE::Gitlab::ExternalAuthorization.rejection_reason(current_user, label)
          rejection_reason ||= _('External authorization denied access to this project')
        end

        if rejection_reason
          access_denied!(rejection_reason)
        else
          super
        end
      end
    end
  end
end
