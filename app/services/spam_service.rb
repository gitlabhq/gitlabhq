class SpamService
  attr_accessor :spammable

  def initialize(spammable)
    @spammable = spammable
  end

  def check(api, request)
    return false unless request && spammable.check_for_spam?
    return false unless akismet.is_spam?(request.env)

    create_spam_log(api, request)
    true
  end

  def mark_as_spam!(current_user)
    return false unless akismet_enabled? && spammable.can_be_submitted?
    if akismet.spam!
      spammable.user_agent_detail.update_attribute(:submitted, true)

      if spammable.is_a?(Issuable)
        SystemNoteService.submit_spam(spammable, spammable.project, current_user)
      end
      true
    else
      false
    end
  end

  def mark_as_ham!
    return false unless spammable.is_a?(SpamLog)

    if akismet.ham!
      spammable.update_attribute(:submitted_as_ham, true)
      true
    else
      false
    end
  end

  private

  def akismet
    @akismet ||= AkismetService.new(spammable)
  end

  def akismet_enabled?
    current_application_settings.akismet_enabled
  end

  def create_spam_log(api, request)
    SpamLog.create(
      {
        user_id: spammable.owner_id,
        title: spammable.spam_title,
        description: spammable.spam_description,
        source_ip: akismet.client_ip(request.env),
        user_agent: akismet.user_agent(request.env),
        noteable_type: spammable.class.to_s,
        via_api: api
      }
    )
  end
end
