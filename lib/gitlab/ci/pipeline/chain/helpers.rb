module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def error(message)
            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
