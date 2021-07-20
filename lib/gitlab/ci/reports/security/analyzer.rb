# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Analyzer
          attr_reader :id, :name, :version, :vendor

          def initialize(id:, name:, version:, vendor:)
            @id = id
            @name = name
            @version = version
            @vendor = vendor
          end
        end
      end
    end
  end
end
