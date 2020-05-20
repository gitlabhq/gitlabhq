# frozen_string_literal: true

module Spam
  class SpamVerdictService
    include AkismetMethods
    include SpamConstants

    def initialize(target:, request:, options:)
      @target = target
      @request = request
      @options = options
    end

    def execute
      if akismet.spam?
        Gitlab::Recaptcha.enabled? ? REQUIRE_RECAPTCHA : DISALLOW
      else
        ALLOW
      end
    end

    private

    attr_reader :target, :request, :options
  end
end
