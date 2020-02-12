# frozen_string_literal: true

module Spam
  class HamService
    include AkismetMethods

    attr_accessor :target, :options

    def initialize(target)
      @target = target
      @user = target.user
      @options = {
          ip_address: target.source_ip,
          user_agent: target.user_agent
      }
    end

    def execute
      if akismet.submit_ham
        target.update_attribute(:submitted_as_ham, true)
      else
        false
      end
    end
  end
end
