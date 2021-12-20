# frozen_string_literal: true

module Clusters
  module Agents
    class ActivityEventPolicy < BasePolicy
      alias_method :event, :subject

      delegate { event.agent }
    end
  end
end
