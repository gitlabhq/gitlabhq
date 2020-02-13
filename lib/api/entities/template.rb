# frozen_string_literal: true

module API
  module Entities
    class Template < Grape::Entity
      expose :name, :content
    end
  end
end
