module SpammableActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if SpamService.new(spammable).mark_as_spam!
      redirect_to spammable, notice: "#{spammable.class.to_s} was submitted to Akismet successfully."
    else
      redirect_to spammable, alert: 'Error with Akismet. Please check the logs for more info.'
    end
  end

  private

  def spammable
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def authorize_submit_spammable!
    access_denied! unless current_user.admin?
  end
end
