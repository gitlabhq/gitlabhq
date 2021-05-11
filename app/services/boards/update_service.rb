# frozen_string_literal: true

module Boards
  class UpdateService < Boards::BaseService
    PERMITTED_PARAMS = %i(name hide_backlog_list hide_closed_list).freeze

    def execute(board)
      filter_params
      board.update(params)
    end

    def filter_params
      params.slice!(*permitted_params)
    end

    def permitted_params
      PERMITTED_PARAMS
    end
  end
end

Boards::UpdateService.prepend_mod_with('Boards::UpdateService')
