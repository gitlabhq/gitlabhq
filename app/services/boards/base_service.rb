# frozen_string_literal: true

module Boards
  class BaseService < ::BaseService
    # Parent can either a group or a project
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent = parent
      @current_user = user
      @params = params.dup
    end
  end
end

Boards::BaseService.prepend_mod_with('Boards::BaseService')
