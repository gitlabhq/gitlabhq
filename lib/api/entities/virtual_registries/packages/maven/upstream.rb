# frozen_string_literal: true

module API
  module Entities
    module VirtualRegistries
      module Packages
        module Maven
          class Upstream < Grape::Entity
            expose :id, :group_id, :url, :cache_validity_hours, :created_at, :updated_at
          end
        end
      end
    end
  end
end
