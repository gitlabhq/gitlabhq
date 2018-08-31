module Gitlab
  module Serializer
    module Ci
      module Options
        extend self

        def load(string)
          return unless string

          YAML.safe_load(string, [Symbol])
        end

        def dump(object)
          YAML.dump(object)
        end
      end
    end
  end
end
