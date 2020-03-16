# frozen_string_literal: true

module ConfirmEmailWarning
  extend ActiveSupport::Concern

  included do
    before_action :set_confirm_warning, if: :show_confirm_warning?
  end

  protected

  def show_confirm_warning?
    html_request? && request.get? && Feature.enabled?(:soft_email_confirmation)
  end

  def set_confirm_warning
    return unless current_user
    return if current_user.confirmed?

    email = current_user.unconfirmed_email || current_user.email

    flash.now[:warning] = _("Please check your email (%{email}) to verify that you own this address and unlock the power of CI/CD. Didn't receive it? %{resend_link}. Wrong email address? %{update_link}.").html_safe % {
      email: email,
      resend_link: view_context.link_to(_('Resend it'), user_confirmation_path(user: { email: email }), method: :post),
      update_link: view_context.link_to(_('Update it'), profile_path)
    }
  end
end
