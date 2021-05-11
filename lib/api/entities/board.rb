# frozen_string_literal: true

module API
  module Entities
    class Board < Grape::Entity
      expose :id
      expose :name
      expose :hide_backlog_list
      expose :hide_closed_list
      expose :project, using: Entities::BasicProjectDetails

      expose :lists, using: Entities::List do |board|
        board.destroyable_lists
      end
    end
  end
end

API::Entities::Board.prepend_mod_with('API::Entities::Board')
