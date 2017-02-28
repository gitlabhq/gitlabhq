# SpamCheckService
#
# Provide helper methods for checking if a given spammable object has
# potential spam data.
#
# Dependencies:
# - params with :request
#
module SpamCheckService
  def filter_spam_check_params
    @request            = params.delete(:request)
    @api                = params.delete(:api)
    @recaptcha_verified = params.delete(:recaptcha_verified)
    @spam_log_id        = params.delete(:spam_log_id)
  end

  def spam_check(spammable, user)
    spam_service = SpamService.new(spammable, @request)

    spam_service.when_recaptcha_verified(@recaptcha_verified, @api) do
      user.spam_logs.find_by(id: @spam_log_id).try(:update!, recaptcha_verified: true)
    end
  end
end
