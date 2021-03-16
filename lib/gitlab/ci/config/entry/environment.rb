# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an environment.
        #
        class Environment < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = %i[name url action on_stop auto_stop_in kubernetes deployment_tier].freeze

          entry :kubernetes, Entry::Kubernetes, description: 'Kubernetes deployment configuration.'

          validations do
            validate do
              unless hash? || string?
                errors.add(:config, 'should be a hash or a string')
              end
            end

            validates :name, presence: true
            validates :name,
              type: {
                with: String,
                message: Gitlab::Regex.environment_name_regex_message
              }

            validates :name,
              format: {
                with: Gitlab::Regex.environment_name_regex,
                message: Gitlab::Regex.environment_name_regex_message
              }

            with_options if: :hash? do
              validates :config, allowed_keys: ALLOWED_KEYS

              validates :url,
                        type: String,
                        length: { maximum: 255 },
                        allow_nil: true

              validates :action,
                        type: String,
                        inclusion: { in: %w[start stop prepare], message: 'should be start, stop or prepare' },
                        allow_nil: true

              validates :deployment_tier,
                        type: String,
                        inclusion: { in: ::Environment.tiers.keys, message: "must be one of #{::Environment.tiers.keys.join(', ')}" },
                        allow_nil: true

              validates :on_stop, type: String, allow_nil: true
              validates :kubernetes, type: Hash, allow_nil: true
              validates :auto_stop_in, duration: true, allow_nil: true
            end
          end

          def hash?
            @config.is_a?(Hash)
          end

          def string?
            @config.is_a?(String)
          end

          def name
            value[:name]
          end

          def url
            value[:url]
          end

          def action
            value[:action] || 'start'
          end

          def on_stop
            value[:on_stop]
          end

          def kubernetes
            value[:kubernetes]
          end

          def auto_stop_in
            value[:auto_stop_in]
          end

          def deployment_tier
            value[:deployment_tier]
          end

          def value
            case @config
            when String then { name: @config, action: 'start' }
            when Hash then @config
            else {}
            end
          end

          def skip_config_hash_validation?
            true
          end
        end
      end
    end
  end
end
