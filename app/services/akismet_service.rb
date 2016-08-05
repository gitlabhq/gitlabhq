class AkismetService
  attr_accessor :spammable

  def initialize(spammable)
    @spammable = spammable
  end

  def client_ip(env)
    env['action_dispatch.remote_ip'].to_s
  end

  def user_agent(env)
    env['HTTP_USER_AGENT']
  end

  def is_spam?(environment)
    ip_address = client_ip(environment)
    user_agent = user_agent(environment)

    params = {
      type: 'comment',
      text: spammable.spammable_text,
      created_at: DateTime.now,
      author: spammable.owner.name,
      author_email: spammable.owner.email,
      referrer: environment['HTTP_REFERER'],
    }

    begin
      is_spam, is_blatant = akismet_client.check(ip_address, user_agent, params)
      is_spam || is_blatant
    rescue => e
      Rails.logger.error("Unable to connect to Akismet: #{e}, skipping check")
      false
    end
  end

  def ham!
    params = {
      type: 'comment',
      text: spammable.text,
      author: spammable.user.name,
      author_email: spammable.user.email
    }

    begin
      akismet_client.submit_ham(spammable.source_ip, spammable.user_agent, params)
      true
    rescue => e
      Rails.logger.error("Unable to connect to Akismet: #{e}, skipping!")
      false
    end
  end

  def spam!
    params = {
      type: 'comment',
      text: spammable.spammable_text,
      author: spammable.owner.name,
      author_email: spammable.owner.email
    }

    begin
      akismet_client.submit_spam(spammable.user_agent_detail.ip_address, spammable.user_agent_detail.user_agent, params)
      true
    rescue => e
      Rails.logger.error("Unable to connect to Akismet: #{e}, skipping!")
      false
    end
  end

  private

  def akismet_client
    @akismet_client ||= ::Akismet::Client.new(current_application_settings.akismet_api_key,
                                              Gitlab.config.gitlab.url)
  end
end
