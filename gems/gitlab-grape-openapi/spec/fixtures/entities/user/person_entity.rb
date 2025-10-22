# frozen_string_literal: true

module TestEntities
  module User
    class PersonEntity < Grape::Entity
      expose :id
    end
  end
end
