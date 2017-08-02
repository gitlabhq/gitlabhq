module SpammableActions
  extend ActiveSupport::Concern

  include Recaptcha::Verify

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if SpamService.new(spammable).mark_as_spam!
      redirect_to spammable_path, notice: "#{spammable.spammable_entity_type.titlecase} was submitted to Akismet successfully."
    else
      redirect_to spammable_path, alert: 'Error with Akismet. Please check the logs for more info.'
    end
  end

  private

  def ensure_spam_config_loaded!
    return @spam_config_loaded if defined?(@spam_config_loaded)

    @spam_config_loaded = Gitlab::Recaptcha.load_configurations!
  end

  def recaptcha_check_with_fallback(&fallback)
    if spammable.valid?
      redirect_to spammable_path
    elsif render_recaptcha?
      ensure_spam_config_loaded!

      if params[:recaptcha_verification]
        flash[:alert] = 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
      end

      render :verify
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
