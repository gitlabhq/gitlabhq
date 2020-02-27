# frozen_string_literal: true

module Spam
  class MarkAsSpamService
    include ::AkismetMethods

    attr_accessor :target, :options

    def initialize(target:)
      @target = target
      @options = {}

      @options[:ip_address] = @target.ip_address
      @options[:user_agent] = @target.user_agent
    end

    def execute
      return unless target.submittable_as_spam?
      return unless akismet.submit_spam

      target.user_agent_detail.update_attribute(:submitted, true)
    end
  end
end
