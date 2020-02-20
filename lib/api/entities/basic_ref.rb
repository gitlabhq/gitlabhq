# frozen_string_literal: true

module API
  module Entities
    class BasicRef < Grape::Entity
      expose :type, :name
    end
  end
end
