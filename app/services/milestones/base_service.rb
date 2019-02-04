# frozen_string_literal: true

module Milestones
  class BaseService < ::BaseService
    # Parent can either a group or a project
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent, @current_user, @params = parent, user, params.dup
      super
    end
  end
end
