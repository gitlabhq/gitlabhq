# frozen_string_literal: true

module QA
  module Runtime
    class GPG
      attr_reader :key_id

      delegate :shell, to: 'QA::Service::Shellout'

      def initialize
        @key_id = 'B8358D73048DACC4'
      end

      def key
        return @key if defined?(@key)

        shell("gpg --import #{Path.fixture('gpg', 'admin.asc')}")
        @key = shell("gpg --armor --export #{key_id}")
      end
    end
  end
end
