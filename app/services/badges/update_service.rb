# frozen_string_literal: true

module Badges
  class UpdateService < Badges::BaseService
    # returns the updated badge
    def execute(badge)
      if params.present?
        badge.update(params)
      end

      badge
    end
  end
end
