# frozen_string_literal: true

module TestEntities
  module User
    class PersonEntity < Grape::Entity
      expose :id # rubocop:disable API/EntityFieldType -- needed for testing purposes
    end
  end
end
