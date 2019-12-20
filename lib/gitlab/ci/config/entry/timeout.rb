# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents the interrutible value.
        #
        class Timeout < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, duration: { limit: ChronicDuration.output(Project::MAX_BUILD_TIMEOUT) }
          end
        end
      end
    end
  end
end
