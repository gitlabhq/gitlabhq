# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class BaseEntity < Grape::Entity
        include Gitlab::Routing
        include GitlabRoutingHelper

        format_with(:string) { |value| value.to_s }

        expose :update_sequence_id, as: :updateSequenceId

        private

        def update_sequence_id
          options[:update_sequence_id] || Client.generate_update_sequence_id
        end
      end
    end
  end
end
