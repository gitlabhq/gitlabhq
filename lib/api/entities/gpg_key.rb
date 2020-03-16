# frozen_string_literal: true

module API
  module Entities
    class GpgKey < Grape::Entity
      expose :id, :key, :created_at
    end
  end
end
