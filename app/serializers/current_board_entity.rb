# frozen_string_literal: true

class CurrentBoardEntity < Grape::Entity
  expose :id
  expose :name
end

CurrentBoardEntity.prepend_if_ee('EE::CurrentBoardEntity')
