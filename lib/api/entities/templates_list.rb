# frozen_string_literal: true

module API
  module Entities
    class TemplatesList < Grape::Entity
      expose :key
      expose :name
    end
  end
end
