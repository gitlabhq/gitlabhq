# frozen_string_literal: true

module Spam
  ##
  # This class is a Parameter Object (https://refactoring.com/catalog/introduceParameterObject.html)
  # which acts as an container abstraction for multiple values related to spam and
  # captcha processing for a provided HTTP request object.
  #
  # It is used to encapsulate these values and allow them to be passed from the Controller/GraphQL
  # layers down into to the Service layer, without needing to pass the entire request and therefore
  # unnecessarily couple the Service layer to the HTTP request.
  #
  # Values contained are:
  #
  # captcha_response: The response resulting from the user solving a captcha.  Currently it is
  #   a scalar reCAPTCHA response string, but it can be expanded to an object in the future to
  #   support other captcha implementations such as FriendlyCaptcha. Obtained from
  #   request.headers['X-GitLab-Captcha-Response']
  # spam_log_id: The id of a SpamLog record. Obtained from request.headers['X-GitLab-Spam-Log-Id']
  # ip_address = The remote IP. Obtained from request.env['action_dispatch.remote_ip']
  # user_agent = The user agent. Obtained from request.env['HTTP_USER_AGENT']
  # referer = The HTTP referer. Obtained from request.env['HTTP_REFERER']
  #
  # NOTE: The presence of these values in the request is not currently enforced. If they are missing,
  #      then the spam check may fail, or the SpamLog or UserAgentDetail may have missing fields.
  class SpamParams
    def self.new_from_request(request:)
      self.new(
        captcha_response: request.headers['X-GitLab-Captcha-Response'],
        spam_log_id: request.headers['X-GitLab-Spam-Log-Id'],
        ip_address: request.env['action_dispatch.remote_ip'].to_s,
        user_agent: request.env['HTTP_USER_AGENT'],
        referer: request.env['HTTP_REFERER']
      )
    end

    attr_reader :captcha_response, :spam_log_id, :ip_address, :user_agent, :referer

    def initialize(captcha_response:, spam_log_id:, ip_address:, user_agent:, referer:)
      @captcha_response = captcha_response
      @spam_log_id = spam_log_id
      @ip_address = ip_address
      @user_agent = user_agent
      @referer = referer
    end

    def ==(other)
      other.class <= self.class &&
        other.captcha_response == captcha_response &&
        other.spam_log_id == spam_log_id &&
        other.ip_address == ip_address &&
        other.user_agent == user_agent &&
        other.referer == referer
    end
  end
end
