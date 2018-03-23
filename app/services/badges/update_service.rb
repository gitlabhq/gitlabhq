module Badges
  class UpdateService < Badges::BaseService
    # returns the updated badge
    def execute(badge)
      if params.present?
        badge.update_attributes(params)
      end

      badge
    end
  end
end
