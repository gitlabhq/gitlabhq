# frozen_string_literal: true

module Gitlab
  module WebIde
    class Config
      module Entry
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Terminal < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable
          include Gitlab::Utils::StrongMemoize

          # By default the build will finish in a few seconds, not giving the webide
          # enough time to connect to the terminal. This default script provides
          # those seconds blocking the build from finishing inmediately.
          DEFAULT_SCRIPT = ['sleep 60'].freeze

          ALLOWED_KEYS = %i[image services tags before_script script variables].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, job_port_unique: { data: ->(record) { record.ports } }

            with_options allow_nil: true do
              validates :tags, array_of_strings: true
            end
          end

          entry :before_script, ::Gitlab::Ci::Config::Entry::Script,
            description: 'Global before script overridden in this job.'

          entry :script, ::Gitlab::Ci::Config::Entry::Commands,
            description: 'Commands that will be executed in this job.'

          entry :image, ::Gitlab::Ci::Config::Entry::Image,
            description: 'Image that will be used to execute this job.'

          entry :services, ::Gitlab::Ci::Config::Entry::Services,
            description: 'Services that will be used to execute this job.'

          entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
            description: 'Environment variables available for this job.'

          attributes :tags

          def value
            to_hash.compact
          end

          private

          def to_hash
            {
              tag_list: tags || [],
              yaml_variables: yaml_variables, # https://gitlab.com/gitlab-org/gitlab/-/issues/300581
              job_variables: yaml_variables,
              options: {
                image: image_value,
                services: services_value,
                before_script: before_script_value,
                script: script_value || DEFAULT_SCRIPT
              }.compact
            }.compact
          end

          def yaml_variables
            strong_memoize(:yaml_variables) do
              next unless variables_value

              variables_value.map do |key, value|
                { key: key.to_s, value: value, public: true }
              end
            end
          end
        end
      end
    end
  end
end
