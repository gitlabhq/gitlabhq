# frozen_string_literal: true

module Captcha
  ##
  # Encapsulates logic of checking captchas.
  #
  class CaptchaVerificationService
    include Recaptcha::Verify

    ##
    # Performs verification of a captcha response.
    #
    # 'captcha_response' parameter is the response from the user solving a client-side captcha.
    #
    # 'request' parameter is the request which submitted the captcha.
    #
    # NOTE: Currently only supports reCAPTCHA, and is not yet used in all places of the app in which
    # captchas are verified, but these can be addressed in future MRs.  See:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/273480
    def execute(captcha_response: nil, request:)
      return false unless captcha_response

      @request = request

      Gitlab::Recaptcha.load_configurations!

      # NOTE: We could pass the model and let the recaptcha gem automatically add errors to it,
      # but we do not, for two reasons:
      #
      # 1. We want control over when the errors are added
      # 2. We want control over the wording and i18n of the message
      # 3. We want a consistent interface and behavior when adding support for other captcha
      #    libraries which may not support automatically adding errors to the model.
      verify_recaptcha(response: captcha_response)
    end

    private

    # The recaptcha library's Recaptcha::Verify#verify_recaptcha method requires that
    # 'request' be a readable attribute - it doesn't support passing it as an options argument.
    attr_reader :request
  end
end
