# frozen_string_literal: true

module DesignManagement
  class MoveDesignsService < DesignService
    # @param user [User] The current user
    # @param [Hash] params
    # @option params [DesignManagement::Design] :current_design
    # @option params [DesignManagement::Design] :previous_design (nil)
    # @option params [DesignManagement::Design] :next_design (nil)
    def initialize(user, params)
      super(nil, user, params.merge(issue: nil))
    end

    def execute
      return error(:no_focus) unless current_design.present?
      return error(:cannot_move) unless ::Feature.enabled?(:reorder_designs, project)
      return error(:cannot_move) unless current_user.can?(:move_design, current_design)
      return error(:no_neighbors) unless neighbors.present?
      return error(:not_distinct) unless all_distinct?
      return error(:not_adjacent) if any_in_gap?
      return error(:not_same_issue) unless all_same_issue?

      current_design.move_between(previous_design, next_design)
      success
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def success
      ServiceResponse.success
    end

    private

    delegate :issue, :project, to: :current_design

    def neighbors
      [previous_design, next_design].compact
    end

    def all_distinct?
      ids.uniq.size == ids.size
    end

    def any_in_gap?
      return false unless previous_design && next_design

      !previous_design.immediately_before?(next_design)
    end

    def all_same_issue?
      issue.designs.id_in(ids).count == ids.size
    end

    def ids
      @ids ||= [current_design, *neighbors].map(&:id)
    end

    def current_design
      params[:current_design]
    end

    def previous_design
      params[:previous_design]
    end

    def next_design
      params[:next_design]
    end
  end
end
