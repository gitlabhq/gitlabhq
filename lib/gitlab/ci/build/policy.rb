# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        def self.fabricate(specs)
          specifications = specs.to_h.map do |spec, value|
            self.const_get(spec.to_s.camelize, false).new(value)
          end

          specifications.compact
        end
      end
    end
  end
end
