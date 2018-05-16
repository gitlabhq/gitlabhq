module EE
  module Ldap
    module OmniauthCallbacksController
      extend ::Gitlab::Utils::Override

      override :sign_in_and_redirect
      def sign_in_and_redirect(user)
        # The counter gets incremented in `sign_in_and_redirect`
        show_ldap_sync_flash if user.sign_in_count == 0

        super
      end

      private

      def show_ldap_sync_flash
        flash[:notice] = 'LDAP sync in progress. This could take a few minutes. '\
                         'Refresh the page to see the changes.'
      end
    end
  end
end
