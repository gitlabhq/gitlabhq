# frozen_string_literal: true

module API
  module Entities
    class Board < Grape::Entity
      expose :id
      expose :name
      expose :project, using: Entities::BasicProjectDetails

      expose :lists, using: Entities::List do |board|
        board.destroyable_lists
      end
    end
  end
end

API::Entities::Board.prepend_if_ee('EE::API::Entities::Board')
