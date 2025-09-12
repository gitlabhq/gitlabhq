# frozen_string_literal: true

module API
  module Entities
    class Approvals < Grape::Entity
      expose :user, using: ::API::Entities::UserBasic
      expose :created_at, as: :approved_at, documentation: { type: 'dateTime', example: '2025-01-01T10:00:00Z' }
    end
  end
end
