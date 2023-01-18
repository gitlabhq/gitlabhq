# frozen_string_literal: true

module Achievements
  class CreateService < BaseService
    def execute
      return error_no_permissions unless allowed?

      achievement = Achievements::Achievement.create(params.merge(namespace_id: @namespace.id))

      return error_creating(achievement) unless achievement.persisted?

      ServiceResponse.success(payload: achievement)
    end

    private

    def error_no_permissions
      error('You have insufficient permissions to create achievements for this namespace')
    end

    def error_creating(achievement)
      error(achievement&.errors&.full_messages || 'Failed to create achievement')
    end
  end
end
