# frozen_string_literal: true

module Spam
  class SpamCheckService
    include AkismetMethods

    attr_accessor :target, :request, :options
    attr_reader :spam_log

    def initialize(target:, request:)
      @target = target
      @request = request
      @options = {}

      if @request
        @options[:ip_address] = @request.env['action_dispatch.remote_ip'].to_s
        @options[:user_agent] = @request.env['HTTP_USER_AGENT']
        @options[:referrer] = @request.env['HTTP_REFERRER']
      else
        @options[:ip_address] = @target.ip_address
        @options[:user_agent] = @target.user_agent
      end
    end

    def execute(api: false, recaptcha_verified:, spam_log_id:, user_id:)
      if recaptcha_verified
        # If it's a request which is already verified through recaptcha,
        # update the spam log accordingly.
        SpamLog.verify_recaptcha!(user_id: user_id, id: spam_log_id)
      else
        # Otherwise, it goes to Akismet for spam check.
        # If so, it assigns target spammable object as "spam" and creates a SpamLog record.
        possible_spam = check(api)
        target.spam = possible_spam unless target.allow_possible_spam?
        target.spam_log = spam_log
      end
    end

    private

    def check(api)
      return unless request
      return unless check_for_spam?
      return unless akismet.spam?

      create_spam_log(api)
      true
    end

    def check_for_spam?
      target.check_for_spam?
    end

    def create_spam_log(api)
      @spam_log = SpamLog.create!(
        {
          user_id: target.author_id,
          title: target.spam_title,
          description: target.spam_description,
          source_ip: options[:ip_address],
          user_agent: options[:user_agent],
          noteable_type: target.class.to_s,
          via_api: api
        }
      )
    end
  end
end
