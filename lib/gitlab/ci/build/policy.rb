module Gitlab
  module Ci
    module Build
      module Policy
        def self.fabricate(specs)
          specifications = specs.to_h.map do |spec, value|
            begin
              self.const_get(spec.to_s.camelize).new(value)
            rescue NameError
              next
            end
          end

          specifications.compact
        end
      end
    end
  end
end
