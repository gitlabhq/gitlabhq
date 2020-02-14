# frozen_string_literal: true

module API
  module Entities
    module InternalPostReceive
      class Message < Grape::Entity
        expose :message
        expose :type
      end
    end
  end
end
