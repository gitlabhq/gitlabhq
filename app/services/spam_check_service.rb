class SpamCheckService
  attr_accessor :request, :api, :spammable

  def initialize(request, api, spammable)
    @request, @api, @spammable = request, api, spammable
  end

  def execute
    if request && spammable.check_for_spam?
      if spammable.spam_detected?(request.env)
        create_spam_log
      end
    end
  end

  private
  
  def spam_log_attrs
    {
      user_id: spammable.owner_id,
      title: spammable.spam_title,
      description: spammable.spam_description,
      source_ip: spammable.client_ip(request.env),
      user_agent: spammable.user_agent(request.env),
      noteable_type: spammable.class.to_s,
      via_api: api
    }
  end

  def create_spam_log
    SpamLog.create(spam_log_attrs)
  end
end
