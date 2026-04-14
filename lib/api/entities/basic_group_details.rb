# frozen_string_literal: true

module API
  module Entities
    class BasicGroupDetails < Grape::Entity
      expose :id, documentation: { type: 'Integer' }
      expose :web_url
      expose :name
    end
  end
end
