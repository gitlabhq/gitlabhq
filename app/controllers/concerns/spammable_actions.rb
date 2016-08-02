module SpammableActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if spammable.submit_spam
      spammable.user_agent_detail.update_attribute(:submitted, true)

      if spammable.is_a?(Issuable)
        SystemNoteService.submit_spam(spammable, spammable.project, current_user)
      end

      redirect_to spammable, notice: 'Issue was submitted to Akismet successfully.'
    else
      flash[:error] = 'Error with Akismet. Please check the logs for more info.'
      redirect_to spammable
    end
  end

  private

  def spammable
    raise NotImplementedError
  end

  def authorize_submit_spammable!
    access_denied! unless current_user.admin?
  end
end
