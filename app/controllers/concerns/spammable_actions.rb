# frozen_string_literal: true

module SpammableActions
  extend ActiveSupport::Concern

  include Recaptcha::Verify
  include Gitlab::Utils::StrongMemoize

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if SpamService.new(spammable: spammable).mark_as_spam!
      redirect_to spammable_path, notice: _("%{spammable_titlecase} was submitted to Akismet successfully.") % { spammable_titlecase: spammable.spammable_entity_type.titlecase }
    else
      redirect_to spammable_path, alert: _('Error with Akismet. Please check the logs for more info.')
    end
  end

  private

  def ensure_spam_config_loaded!
    strong_memoize(:spam_config_loaded) do
      Gitlab::Recaptcha.load_configurations!
    end
  end

  def recaptcha_check_with_fallback(should_redirect = true, &fallback)
    if should_redirect && spammable.valid?
      redirect_to spammable_path
    elsif render_recaptcha?
      ensure_spam_config_loaded!

      if params[:recaptcha_verification]
        flash[:alert] = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
      end

      respond_to do |format|
        format.html do
          render :verify
        end

        format.json do
          locals = { spammable: spammable, script: false, has_submit: false }
          recaptcha_html = render_to_string(partial: 'shared/recaptcha_form', formats: :html, locals: locals)

          render json: { recaptcha_html: recaptcha_html }
        end
      end
    else
      yield
    end
  end

  def spammable_params
    default_params = { request: request }

    recaptcha_check = params[:recaptcha_verification] &&
      ensure_spam_config_loaded! &&
      verify_recaptcha

    return default_params unless recaptcha_check

    { recaptcha_verified: true,
      spam_log_id: params[:spam_log_id] }.merge(default_params)
  end

  def spammable
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def spammable_path
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def authorize_submit_spammable!
    access_denied! unless current_user.admin?
  end

  def render_recaptcha?
    return false if spammable.errors.count > 1 # re-render "new" template in case there are other errors
    return false unless Gitlab::Recaptcha.enabled?

    spammable.spam
  end
end
