# frozen_string_literal: true

module API
  module Entities
    class Metadata < Grape::Entity
      expose :version
      expose :revision
      expose :kas do
        expose :enabled, documentation: { type: 'boolean' }
        expose :externalUrl
        expose :version
      end
    end
  end
end
