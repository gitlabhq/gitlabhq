class AkismetService
  attr_accessor :owner, :text, :options

  def initialize(owner, text, options = {})
    @owner = owner
    @text = text
    @options = options
  end

  def is_spam?
    return false unless akismet_enabled?

    params = {
      type: 'comment',
      text: text,
      created_at: DateTime.now,
      author: owner.name,
      author_email: owner.email,
      referrer: options[:referrer],
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
    return false unless akismet_enabled?

    params = {
      type: 'comment',
      text: text,
      author: owner.name,
      author_email: owner.email
    }

    begin
      akismet_client.submit_ham(options[:ip_address], options[:user_agent], params)
      true
    rescue => e
      Rails.logger.error("Unable to connect to Akismet: #{e}, skipping!")
      false
    end
  end

  def submit_spam
    return false unless akismet_enabled?

    params = {
      type: 'comment',
      text: text,
      author: owner.name,
      author_email: owner.email
    }

    begin
      akismet_client.submit_spam(options[:ip_address], options[:user_agent], params)
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

  def akismet_enabled?
    current_application_settings.akismet_enabled
  end
end
