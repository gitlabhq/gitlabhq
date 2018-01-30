module EE
  module ConfirmationsController
    include EE::Audit::Changes
    extend ::Gitlab::Utils::Override

    protected

    override :after_sign_in
    def after_sign_in(resource)
      audit_changes(:email, as: 'email address', model: resource)

      super(resource)
    end
  end
end
