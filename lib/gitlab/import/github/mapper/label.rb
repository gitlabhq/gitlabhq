module Gitlab
  module Import
    module Github
      module Mapper
        class Label < Base
          private

          def attributes_for(raw)
            {
              project: project,
              title: raw.name,
              color: "##{raw.color}"
            }
          end

          def klass
            ::Label
          end
        end
      end
    end
  end
end
