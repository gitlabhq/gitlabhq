# frozen_string_literal: true

module Spam
  class HamService
    include AkismetMethods

    attr_accessor :spam_log, :options

    def initialize(spam_log)
      @spam_log = spam_log
      @user = spam_log.user
      @options = {
        ip_address: spam_log.source_ip,
        user_agent: spam_log.user_agent
      }
    end

    def execute
      if akismet.submit_ham
        spam_log.update_attribute(:submitted_as_ham, true)
      else
        false
      end
    end

    alias_method :target, :spam_log
  end
end
