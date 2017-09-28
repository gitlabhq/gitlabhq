module EE
  module ConfirmationsController
    include EE::Audit::Changes

    protected

    def after_sign_in(resource)
      raise NotImplementedError unless defined?(super)

      audit_changes(:email, as: 'email address', model: resource)

      super(resource)
    end
  end
end
