# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Evidence
          attr_reader :data

          def initialize(data:)
            @data = data
          end
        end
      end
    end
  end
end
