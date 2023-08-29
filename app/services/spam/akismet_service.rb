# frozen_string_literal: true

module Spam
  class AkismetService
    attr_accessor :text, :options

    def initialize(owner_name, owner_email, text, options = {})
      @owner_name = owner_name
      @owner_email = owner_email
      @text = text
      @options = options
    end

    def spam?
      return false unless akismet_enabled?

      params = {
        type: 'comment',
        text: text,
        created_at: DateTime.current,
        author: owner_name,
        author_email: owner_email,
        # NOTE: The akismet_client needs the option to be named `:referrer`, not `:referer`
        referrer: options[:referer]
      }

      begin
        is_spam, is_blatant = akismet_client.check(options[:ip_address], options[:user_agent], params)
        is_spam || is_blatant
      rescue ArgumentError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        false
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e)
        Gitlab::AppLogger.error("Error during Akismet spam check, flagging as not spam: #{e}")
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

    attr_accessor :owner_name, :owner_email

    def akismet_client
      @akismet_client ||= ::Akismet::Client.new(
        Gitlab::CurrentSettings.akismet_api_key,
        Gitlab.config.gitlab.url
      )
    end

    def akismet_enabled?
      Gitlab::CurrentSettings.akismet_enabled
    end

    def submit(type)
      return false unless akismet_enabled?

      params = {
        type: 'comment',
        text: text,
        author: owner_name,
        author_email: owner_email
      }

      begin
        akismet_client.public_send(type, options[:ip_address], options[:user_agent], params) # rubocop:disable GitlabSecurity/PublicSend
        true
      rescue StandardError => e
        Gitlab::AppLogger.error("Unable to connect to Akismet: #{e}, skipping!")
        false
      end
    end
  end
end
