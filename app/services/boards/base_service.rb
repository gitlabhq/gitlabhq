module Boards
  class BaseService < ::BaseService
    # Parent can either a group or a project
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent, @current_user, @params = parent, user, params.dup
    end

    def set_assignee
      assignee = User.find_by(id: params.delete(:assignee_id))
      params.merge!(assignee: assignee)
    end
  end
end
