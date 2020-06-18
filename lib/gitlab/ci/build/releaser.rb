# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Releaser
        BASE_COMMAND = 'release-cli create'

        attr_reader :config

        def initialize(config:)
          @config = config
        end

        def script
          command = BASE_COMMAND.dup
          config.each { |k, v| command.concat(" --#{k.to_s.dasherize} \"#{v}\"") }

          command
        end
      end
    end
  end
end
