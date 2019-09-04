# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def error(message, config_error: false)
            if config_error && command.save_incompleted
              pipeline.yaml_errors = message
              pipeline.drop!(:config_error)
            end

            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
