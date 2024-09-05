# frozen_string_literal: true

module Gitlab
  module Spamcheck
    class Result
      include ::Spam::SpamConstants

      attr_reader :response

      VERDICT_MAPPING = {
        ::Spamcheck::SpamVerdict::Verdict::ALLOW => ALLOW,
        ::Spamcheck::SpamVerdict::Verdict::CONDITIONAL_ALLOW => CONDITIONAL_ALLOW,
        ::Spamcheck::SpamVerdict::Verdict::DISALLOW => DISALLOW,
        ::Spamcheck::SpamVerdict::Verdict::BLOCK => BLOCK_USER,
        ::Spamcheck::SpamVerdict::Verdict::NOOP => NOOP
      }.freeze

      def initialize(response)
        @response = response
      end

      def score
        response.score
      end

      def verdict
        VERDICT_MAPPING.fetch(::Spamcheck::SpamVerdict::Verdict.resolve(response.verdict), ALLOW)
      end

      def evaluated?
        response.evaluated
      end
    end
  end
end
