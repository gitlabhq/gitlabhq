# frozen_string_literal: true

module Spam
  ##
  # This class is a Parameter Object (https://refactoring.com/catalog/introduceParameterObject.html)
  # which acts as an container abstraction for multiple parameter values related to spam and
  # captcha processing for a request.
  #
  # Values contained are:
  #
  # api: A boolean flag indicating if the request was submitted via the REST or GraphQL API
  # captcha_response: The response resulting from the user solving a captcha.  Currently it is
  #   a scalar reCAPTCHA response string, but it can be expanded to an object in the future to
  #   support other captcha implementations such as FriendlyCaptcha.
  # spam_log_id: The id of a SpamLog record.
  class SpamParams
    attr_reader :api, :captcha_response, :spam_log_id

    def initialize(api:, captcha_response:, spam_log_id:)
      @api = api.present?
      @captcha_response = captcha_response
      @spam_log_id = spam_log_id
    end

    def ==(other)
      other.class <= self.class &&
        other.api == api &&
        other.captcha_response == captcha_response &&
        other.spam_log_id == spam_log_id
    end
  end
end
