# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Releaser
        BASE_COMMAND = 'release-cli create'
        SINGLE_FLAGS = %i[name description tag_name tag_message ref released_at].freeze
        ARRAY_FLAGS = %i[milestones].freeze

        attr_reader :job, :config

        def initialize(job:)
          @job = job
          @config = job.options[:release]
        end

        def script
          command = BASE_COMMAND.dup
          single_flags.each { |k, v| command.concat(" --#{k.to_s.dasherize} \"#{v}\"") }
          array_commands.each { |k, v| v.each { |elem| command.concat(" --#{k.to_s.singularize.dasherize} \"#{elem}\"") } }
          asset_links.each { |link| command.concat(" --assets-link #{stringified_json(link)}") }
          command.concat(" --catalog-publish") if catalog_publish?

          [command.freeze]
        end

        private

        def single_flags
          config.slice(*SINGLE_FLAGS)
        end

        def array_commands
          config.slice(*ARRAY_FLAGS)
        end

        def asset_links
          config.dig(:assets, :links) || []
        end

        def stringified_json(object)
          "#{object.to_json.to_json}"
        end

        def catalog_publish?
          return false if ::Feature.disabled?(:ci_release_cli_catalog_publish_option, job.project)

          job.project.catalog_resource
        end
      end
    end
  end
end
