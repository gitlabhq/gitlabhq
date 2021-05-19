# frozen_string_literal: true

class CurrentBoardEntity < Grape::Entity
  expose :id
  expose :name
  expose :hide_backlog_list
  expose :hide_closed_list
end

CurrentBoardEntity.prepend_mod_with('CurrentBoardEntity')
