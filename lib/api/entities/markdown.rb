# frozen_string_literal: true

module API
  module Entities
    class Markdown < Grape::Entity
      expose :html, documentation: { type: 'string', example: '<p dir=\"auto\">Hello world!</p>"' }
    end
  end
end
