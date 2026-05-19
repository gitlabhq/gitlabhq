# frozen_string_literal: true

module API
  module Entities
    class Board < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :name, documentation: { type: 'String', example: 'Development' }
      expose :hide_backlog_list, documentation: { type: 'Boolean', example: false }
      expose :hide_closed_list, documentation: { type: 'Boolean', example: false }
      expose :project, using: ::API::Entities::BasicProjectDetails

      expose :lists, using: ::API::Entities::List, documentation: { is_array: true } do |board|
        board.destroyable_lists
      end
    end
  end
end

API::Entities::Board.prepend_mod_with('API::Entities::Board')
