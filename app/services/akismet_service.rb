class AkismetService
  attr_accessor :owner, :text, :options

  def initialize(owner, text, options = {})
    @owner = owner
    @text = text
    @options = options
  end

  def spam?
    return false unless akismet_enabled?

    params = {
      type: 'comment',
      text: text,
      created_at: DateTime.now,
      author: owner.name,
      author_email: owner.email,
      referrer: options[:referrer]
    }

    begin
      is_spam, is_blatant = akismet_client.check(options[:ip_address], options[:user_agent], params)
      is_spam || is_blatant
    rescue => e
      Rails.logger.error("Unable to connect to Akismet: #{e}, skipping check")
      false
    end
  end

  def submit_ham
    submit(:ham)
  end

  def submit_spam
    submit(:spam)
  end

  private

  def akismet_client
    @akismet_client ||= ::Akismet::Client.new(Gitlab::CurrentSettings.akismet_api_key,
                                              Gitlab.config.gitlab.url)
  end

  def akismet_enabled?
    Gitlab::CurrentSettings.akismet_enabled
  end

  def submit(type)
    return false unless akismet_enabled?

    params = {
      type: 'comment',
      text: text,
      author: owner.name,
      author_email: owner.email
    }

    begin
      akismet_client.public_send(type, options[:ip_address], options[:user_agent], params) # rubocop:disable GitlabSecurity/PublicSend
      true
    rescue => e
      Rails.logger.error("Unable to connect to Akismet: #{e}, skipping!")
      false
    end
  end
end
