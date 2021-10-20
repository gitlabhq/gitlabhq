# frozen_string_literal: true

module API
  module Entities
    module Ci
      class ResourceGroup < Grape::Entity
        expose :id, :key, :process_mode, :created_at, :updated_at
      end
    end
  end
end
