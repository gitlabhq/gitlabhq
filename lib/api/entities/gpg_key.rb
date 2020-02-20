# frozen_string_literal: true

module API
  module Entities
    class GPGKey < Grape::Entity
      expose :id, :key, :created_at
    end
  end
end
