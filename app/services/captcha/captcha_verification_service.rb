# frozen_string_literal: true

module Captcha
  ##
  # Encapsulates logic of checking captchas.
  #
  class CaptchaVerificationService
    include Recaptcha::Verify

    # Currently the only value that is used out of the request by the reCAPTCHA library
    # is 'remote_ip'. Therefore, we just create a struct to avoid passing the full request
    # object through all the service layer objects, and instead just rely on passing only
    # the required remote_ip value. This eliminates the need to couple the service layer
    # to the HTTP request (for the purpose of this service, at least).
    RequestStruct = Struct.new(:remote_ip)

    def initialize(spam_params:)
      @spam_params = spam_params
    end

    ##
    # Performs verification of a captcha response.
    #
    # NOTE: Currently only supports reCAPTCHA, and is not yet used in all places of the app in which
    # captchas are verified, but these can be addressed in future MRs.  See:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/273480
    def execute
      return false unless spam_params.captcha_response

      @request = RequestStruct.new(spam_params.ip_address)

      Gitlab::Recaptcha.load_configurations!

      # NOTE: We could pass the model and let the recaptcha gem automatically add errors to it,
      # but we do not, for two reasons:
      #
      # 1. We want control over when the errors are added
      # 2. We want control over the wording and i18n of the message
      # 3. We want a consistent interface and behavior when adding support for other captcha
      #    libraries which may not support automatically adding errors to the model.
      verify_recaptcha(response: spam_params.captcha_response)
    end

    private

    attr_reader :spam_params

    # The recaptcha library's Recaptcha::Verify#verify_recaptcha method requires that
    # 'request' be a readable attribute - it doesn't support passing it as an options argument.
    attr_reader :request
  end
end
