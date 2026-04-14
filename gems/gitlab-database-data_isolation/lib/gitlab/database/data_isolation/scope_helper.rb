# frozen_string_literal: true

module Gitlab
  module Database
    module DataIsolation
      module ScopeHelper
        def self.without_data_isolation(&block)
          Context.without_data_isolation(&block)
        end
      end
    end
  end
end
