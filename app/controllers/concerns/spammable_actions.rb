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

  def spammable_params
    # NOTE: For the legacy reCAPTCHA implementation based on the HTML/HAML form, the
    # 'g-recaptcha-response' field name comes from `Recaptcha::ClientHelper#recaptcha_tags` in the
    # recaptcha gem, which is called from the HAML `_recaptcha_form.html.haml` form.
    #
    # It is used in the `Recaptcha::Verify#verify_recaptcha` to extract the value from `params`,
    # if the `response` option is not passed explicitly.
    #
    # Instead of relying on this behavior, we are extracting and passing it explicitly. This will
    # make it consistent with the newer, modern reCAPTCHA verification process as it will be
    # implemented via the GraphQL API and in Vue components via the native reCAPTCHA Javascript API,
    # which requires that the recaptcha response param be obtained and passed explicitly.
    #
    # It can also be expanded to multiple fields when we move to future alternative captcha
    # implementations such as FriendlyCaptcha. See https://gitlab.com/gitlab-org/gitlab/-/issues/273480

    # After this newer GraphQL/JS API process is fully supported by the backend, we can remove the
    # check for the 'g-recaptcha-response' field and other HTML/HAML form-specific support.
    captcha_response = params['g-recaptcha-response'] || params[:captcha_response]

    {
      request: request,
      spam_log_id: params[:spam_log_id],
      captcha_response: captcha_response
    }
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
