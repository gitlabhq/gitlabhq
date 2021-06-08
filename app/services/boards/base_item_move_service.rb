# frozen_string_literal: true

module Boards
  class BaseItemMoveService < Boards::BaseService
    def execute(issuable)
      issuable_modification_params = issuable_params(issuable)
      return false if issuable_modification_params.empty?

      move_single_issuable(issuable, issuable_modification_params)
    end

    private

    def issuable_params(issuable)
      attrs = {}

      if move_between_lists?
        attrs.merge!(
          add_label_ids: add_label_ids,
          remove_label_ids: remove_label_ids,
          state_event: issuable_state
        )
      end

      reposition_ids = move_between_ids(params)
      attrs.merge!(reposition_params(reposition_ids)) if reposition_ids

      attrs
    end

    def reposition_params(reposition_ids)
      reposition_parent.merge(move_between_ids: reposition_ids)
    end

    def move_single_issuable(issuable, issuable_modification_params)
      ability_name = :"admin_#{issuable.to_ability_name}"
      return unless can?(current_user, ability_name, issuable)

      update(issuable, issuable_modification_params)
    end

    def move_between_lists?
      moving_from_list.present? && moving_to_list.present? &&
        moving_from_list != moving_to_list
    end

    def moving_from_list
      return unless params[:from_list_id].present?

      @moving_from_list ||= board.lists.id_in(params[:from_list_id]).first
    end

    def moving_to_list
      return unless params[:to_list_id].present?

      @moving_to_list ||= board.lists.id_in(params[:to_list_id]).first
    end

    def issuable_state
      return 'reopen' if moving_from_list.closed?
      return 'close'  if moving_to_list.closed?
    end

    def add_label_ids
      [moving_to_list.label_id].compact
    end

    def remove_label_ids
      label_ids =
        if moving_to_list.movable?
          moving_from_list.label_id
        else
          board_label_ids
        end

      Array(label_ids).compact
    end

    def board_label_ids
      ::Label.ids_on_board(board.id)
    end

    def move_between_ids(move_params)
      ids = [move_params[:move_after_id], move_params[:move_before_id]]
              .map(&:to_i)
              .map { |m| m > 0 ? m : nil }

      ids.any? ? ids : nil
    end
  end
end
