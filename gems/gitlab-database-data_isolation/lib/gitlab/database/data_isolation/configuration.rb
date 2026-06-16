# frozen_string_literal: true

module Gitlab
  module Database
    module DataIsolation
      class Configuration
        attr_accessor :current_sharding_key_value, :sharding_key_map, :strategy

        def initialize
          @current_sharding_key_value = ->(_table) {}
          @sharding_key_map = {}
          @strategy = :arel
        end
      end
    end
  end
end
