# frozen_string_literal: true

module SpammableActions::AkismetMarkAsSpamAction
  extend ActiveSupport::Concern
  include SpammableActions::Attributes

  included do
    before_action :authorize_submit_spammable!, only: :mark_as_spam
  end

  def mark_as_spam
    if Spam::AkismetMarkAsSpamService.new(target: spammable).execute
      redirect_to spammable_path, notice: _("%{spammable_titlecase} was submitted to Akismet successfully.") % { spammable_titlecase: spammable.spammable_entity_type.titlecase }
    else
      redirect_to spammable_path, alert: _('Error with Akismet. Please check the logs for more info.')
    end
  end

  private

  def authorize_submit_spammable!
    access_denied! unless current_user.can_admin_all_resources?
  end

  def spammable_path
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end
end
