# frozen_string_literal: true

module API
  module Entities
    class Changelog < Grape::Entity
      expose :to_s, as: :notes, documentation: { type: 'String', example: '## 1.0.0 (2023-01-01)' }
    end
  end
end
