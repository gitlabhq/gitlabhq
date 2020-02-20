# frozen_string_literal: true

module API
  module Entities
    class Contributor < Grape::Entity
      expose :name, :email, :commits, :additions, :deletions
    end
  end
end
