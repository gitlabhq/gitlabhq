# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Releaser
        BASE_COMMAND = 'release-cli create'
        SINGLE_FLAGS = %i[name description tag_name ref released_at].freeze
        ARRAY_FLAGS = %i[milestones].freeze

        attr_reader :config

        def initialize(config:)
          @config = config
        end

        def script
          command = BASE_COMMAND.dup
          single_flags.each { |k, v| command.concat(" --#{k.to_s.dasherize} \"#{v}\"") }
          array_commands.each { |k, v| v.each { |elem| command.concat(" --#{k.to_s.singularize.dasherize} \"#{elem}\"") } }

          [command]
        end

        private

        def single_flags
          config.slice(*SINGLE_FLAGS)
        end

        def array_commands
          config.slice(*ARRAY_FLAGS)
        end
      end
    end
  end
end
