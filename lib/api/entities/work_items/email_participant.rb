# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      class EmailParticipant < Grape::Entity
        include ConditionalExposureHelpers

        expose :id, documentation: { type: 'Integer', format: 'int64', example: 42 }

        expose :email,
          documentation: { type: 'String', example: 'us**@ex*****.com' } do |participant, options|
          IssueEmailParticipantPresenter.new(
            participant, current_user: options[:current_user]
          ).email
        end

        expose_field :created_at,
          documentation: { type: 'DateTime', example: '2024-01-15T10:00:00.000Z' }

        expose_field :updated_at,
          documentation: { type: 'DateTime', example: '2024-01-15T10:00:00.000Z' }
      end
    end
  end
end
