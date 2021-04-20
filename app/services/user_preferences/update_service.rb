# frozen_string_literal: true

module UserPreferences
  class UpdateService < BaseService
    def initialize(user, params = {})
      @preferences = user.user_preference
      @params = params.to_h.dup.with_indifferent_access
    end

    def execute
      if @preferences.update(@params)
        ServiceResponse.success(
          message: 'Preference was updated',
          payload: { preferences: @preferences })
      else
        ServiceResponse.error(message: 'Could not update preference')
      end
    end
  end
end
