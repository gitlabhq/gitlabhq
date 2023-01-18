# frozen_string_literal: true

module GitlabRecaptcha
  extend ActiveSupport::Concern
  include Recaptcha::Adapters::ControllerMethods
  include RecaptchaHelper

  def load_recaptcha
    recaptcha_enabled? && Gitlab::Recaptcha.load_configurations!
  end

  def check_recaptcha
    return unless load_recaptcha
    return if verify_recaptcha

    flash[:alert] = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
    flash.delete :recaptcha_error

    self.resource = resource_class.new

    add_gon_variables

    render action: 'new'
  end
end
