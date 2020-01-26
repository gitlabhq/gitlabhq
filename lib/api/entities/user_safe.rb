# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      expose :id, :name, :username
    end
  end
end
