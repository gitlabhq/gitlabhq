# frozen_string_literal: true

module Boards
  class VisitsFinder
    attr_accessor :params, :current_user, :parent

    def initialize(parent, current_user)
      @current_user = current_user
      @parent = parent
    end

    def execute(count = nil)
      return unless current_user

      recent_visit_model.latest(current_user, parent, count: count)
    end

    alias_method :latest, :execute

    private

    def recent_visit_model
      parent.is_a?(Group) ? BoardGroupRecentVisit : BoardProjectRecentVisit
    end
  end
end
