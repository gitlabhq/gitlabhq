# frozen_string_literal: true

# SpamCheckMethods
#
# Provide helper methods for checking if a given target spammable object has
# potential spam data.
#
# Dependencies:
# - params with :request

module SpamCheckMethods
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def filter_spam_check_params
    @request            = params.delete(:request)
    @api                = params.delete(:api)
    @recaptcha_verified = params.delete(:recaptcha_verified)
    @spam_log_id        = params.delete(:spam_log_id)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  # In order to be proceed to the spam check process, @target has to be
  # a dirty instance, which means it should be already assigned with the new
  # attribute values.
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def spam_check(spammable, user)
    Spam::SpamCheckService.new(
      target: spammable,
      request: @request
    ).execute(
      api: @api,
      recaptcha_verified: @recaptcha_verified,
      spam_log_id: @spam_log_id,
      user_id: user.id)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
