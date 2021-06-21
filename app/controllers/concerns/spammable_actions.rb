# frozen_string_literal: true

module SpammableActions
  extend ActiveSupport::Concern
  include Spam::Concerns::HasSpamActionResponseFields

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if Spam::MarkAsSpamService.new(target: spammable).execute
      redirect_to spammable_path, notice: _("%{spammable_titlecase} was submitted to Akismet successfully.") % { spammable_titlecase: spammable.spammable_entity_type.titlecase }
    else
      redirect_to spammable_path, alert: _('Error with Akismet. Please check the logs for more info.')
    end
  end

  private

  def recaptcha_check_with_fallback(should_redirect = true, &fallback)
    if should_redirect && spammable.valid?
      redirect_to spammable_path
    elsif spammable.render_recaptcha?
      Gitlab::Recaptcha.load_configurations!

      respond_to do |format|
        format.html do
          # NOTE: format.html is still used by issue create, and uses the legacy HAML
          # `_recaptcha_form.html.haml` rendered via the `projects/issues/verify` template.
          render :verify
        end

        format.json do
          # format.json is used by all new Vue-based CAPTCHA implementations, which
          # handle all of the CAPTCHA form rendering on the client via the Pajamas-based
          # app/assets/javascripts/captcha/captcha_modal.vue

          # NOTE: "409 - Conflict" seems to be the most appropriate HTTP status code for a response
          # which requires a CAPTCHA to be solved in order for the request to be resubmitted.
          # See https://stackoverflow.com/q/26547466/25192
          render json: spam_action_response_fields(spammable), status: :conflict
        end
      end
    else
      yield
    end
  end

  # TODO: This method is currently only needed for issue create and update. It can be removed when:
  #
  # 1. Issue create is is converted to a client/JS based approach instead of the legacy HAML
  #    `_recaptcha_form.html.haml` which is rendered via the `projects/issues/verify` template.
  #    In this case, which is based on the legacy reCAPTCHA implementation using the HTML/HAML form,
  #    the 'g-recaptcha-response' field name comes from `Recaptcha::ClientHelper#recaptcha_tags` in the
  #    recaptcha gem, which is called from the HAML `_recaptcha_form.html.haml` form.
  # 2. Issue update is converted to use the headers-based approach, which will require adding
  #    support to captcha_modal_axios_interceptor.js like we have already added to
  #    apollo_captcha_link.js.
  #    In this case, the `captcha_response` field name comes from our captcha_modal_axios_interceptor.js.
  def extract_legacy_spam_params_to_headers
    request.headers['X-GitLab-Captcha-Response'] = params['g-recaptcha-response'] || params[:captcha_response]
    request.headers['X-GitLab-Spam-Log-Id'] = params[:spam_log_id]
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
end
