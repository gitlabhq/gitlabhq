# frozen_string_literal: true

module Milestones
  class BaseService < ::BaseService
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      # Parent can either a group or a project
      @parent = parent
      @current_user = user
      @params = params.dup

      super
    end

    private

    def execute_hooks(milestone, action)
      # At the moment, only project milestones support webhooks, not group milestones
      return unless milestone.project_milestone?
      return unless milestone.parent.has_active_hooks?(:milestone_hooks)

      payload = Gitlab::DataBuilder::Milestone.build(milestone, action)
      milestone.parent.execute_hooks(payload, :milestone_hooks)
    end
  end
end
