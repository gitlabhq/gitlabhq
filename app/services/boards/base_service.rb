module Boards
  class BaseService < ::BaseService
    # Parent can either a group or a project
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent, @current_user, @params = parent, user, params.dup
    end
  end
end
