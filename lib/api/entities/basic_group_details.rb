# frozen_string_literal: true

module API
  module Entities
    class BasicGroupDetails < Grape::Entity
      expose :id
      expose :web_url
      expose :name
    end
  end
end
