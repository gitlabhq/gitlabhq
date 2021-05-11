# frozen_string_literal: true

class BoardSimpleEntity < Grape::Entity
  expose :id
  expose :name
end

BoardSimpleEntity.prepend_mod_with('BoardSimpleEntity')
