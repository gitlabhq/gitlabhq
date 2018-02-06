class HamService
  attr_accessor :spam_log

  def initialize(spam_log)
    @spam_log = spam_log
  end

  def mark_as_ham!
    if akismet.submit_ham
      spam_log.update_attribute(:submitted_as_ham, true)
    else
      false
    end
  end

  private

  def akismet
    @akismet ||= AkismetService.new(
      spam_log.user,
      spam_log.text,
      ip_address: spam_log.source_ip,
      user_agent: spam_log.user_agent
    )
  end
end
