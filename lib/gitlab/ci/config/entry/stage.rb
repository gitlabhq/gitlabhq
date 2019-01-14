# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a stage for a job.
        #
        class Stage < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: String
          end

          def self.default
            'test'
          end
        end
      end
    end
  end
end
