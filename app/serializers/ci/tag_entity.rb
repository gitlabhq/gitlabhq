# frozen_string_literal: true

module Ci
  class TagEntity < Grape::Entity
    expose :id
    expose :name
  end
end
