module Gitlab
  module GithubImport
    class HookFormatter
      EVENTS = %w[* create delete pull_request push].freeze

      attr_reader :raw

      delegate :id, :name, :active, to: :raw

      def initialize(raw)
        @raw = raw
      end

      def config
        raw.config.attrs
      end

      def valid?
        (EVENTS & raw.events).any? && active
      end
    end
  end
end
