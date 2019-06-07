# frozen_string_literal: true

module Groups
  class BaseService < ::BaseService
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group, @current_user, @params = group, user, params.dup
    end

    private

    def remove_unallowed_params
      # overridden in EE
    end
  end
end
