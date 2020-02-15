# frozen_string_literal: true

module Spam
  class MarkAsSpamService
    include ::AkismetMethods

    attr_accessor :spammable, :options

    def initialize(spammable:)
      @spammable = spammable
      @options = {}

      @options[:ip_address] = @spammable.ip_address
      @options[:user_agent] = @spammable.user_agent
    end

    def execute
      return unless spammable.submittable_as_spam?
      return unless akismet.submit_spam

      spammable.user_agent_detail.update_attribute(:submitted, true)
    end
  end
end
