class SpamService
  attr_accessor :spammable, :request, :options

  def initialize(spammable, request = nil)
    @spammable = spammable
    @request = request
    @options = {}

    if @request
      @options[:ip_address] = @request.env['action_dispatch.remote_ip'].to_s
      @options[:user_agent] = @request.env['HTTP_USER_AGENT']
      @options[:referrer] = @request.env['HTTP_REFERRER']
    else
      @options[:ip_address] = @spammable.ip_address
      @options[:user_agent] = @spammable.user_agent
    end
  end

  def check(api = false)
    return false unless request && check_for_spam?

    return false unless akismet.is_spam?

    create_spam_log(api)
    true
  end

  def mark_as_spam!
    return false unless spammable.submittable_as_spam?

    if akismet.submit_spam
      spammable.user_agent_detail.update_attribute(:submitted, true)
    else
      false
    end
  end

  private

  def akismet
    @akismet ||= AkismetService.new(
      spammable_owner,
      spammable.spammable_text,
      options
    )
  end

  def spammable_owner
    @user ||= User.find(spammable_owner_id)
  end

  def spammable_owner_id
    @owner_id ||=
      if spammable.respond_to?(:author_id)
        spammable.author_id
      elsif spammable.respond_to?(:creator_id)
        spammable.creator_id
      end
  end

  def check_for_spam?
    spammable.check_for_spam?
  end

  def create_spam_log(api)
    SpamLog.create(
      {
        user_id: spammable_owner_id,
        title: spammable.spam_title,
        description: spammable.spam_description,
        source_ip: options[:ip_address],
        user_agent: options[:user_agent],
        noteable_type: spammable.class.to_s,
        via_api: api
      }
    )
  end
end
