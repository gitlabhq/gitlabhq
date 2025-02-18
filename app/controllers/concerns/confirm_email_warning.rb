# frozen_string_literal: true

module ConfirmEmailWarning
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  included do
    before_action :set_confirm_warning, if: :show_confirm_warning?
  end

  protected

  def show_confirm_warning?
    html_request? && request.get? && Gitlab::CurrentSettings.email_confirmation_setting_soft?
  end

  def set_confirm_warning
    return unless current_user
    return if current_user.confirmed?

    flash.now[:warning] = format(
      confirm_warning_message,
      email: email_to_display,
      resend_link: view_context.link_to(_('Resend it'), user_confirmation_path(user: { email: email }), method: :post),
      update_link: view_context.link_to(_('Update it'), user_settings_profile_path)
    ).html_safe
  end

  private

  def email
    current_user.unconfirmed_email || current_user.email
  end
  strong_memoize_attr :email

  def confirm_warning_message
    _("Please check your email (%{email}) to verify that you own this address and unlock the power of CI/CD. " \
      "Didn't receive it? %{resend_link}. Wrong email address? %{update_link}.")
  end

  def email_to_display
    ERB::Util.html_escape(email)
  end
end
