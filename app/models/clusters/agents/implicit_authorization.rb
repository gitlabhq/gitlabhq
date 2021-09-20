# frozen_string_literal: true

module Clusters
  module Agents
    class ImplicitAuthorization
      attr_reader :agent

      delegate :id, to: :agent, prefix: true
      delegate :project, to: :agent

      def initialize(agent:)
        @agent = agent
      end

      def config
        nil
      end
    end
  end
end
