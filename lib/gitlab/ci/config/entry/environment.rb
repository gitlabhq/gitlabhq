module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents an environment.
        #
        class Environment < Node
          include Validatable

          ALLOWED_KEYS = %i[name rollout url action on_stop].freeze

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
                        length: { maximum: 255 },
                        allow_nil: true

              validates :action,
                        inclusion: { in: %w[start stop], message: 'should be start or stop' },
                        allow_nil: true

              validates :on_stop, type: String, allow_nil: true

              validates :track,
                        inclusion: { in: %w[stable rollout canary], message: 'should be start or stop' },
                        allow_nil: true

              validates :rollout,
                        presence: true,
                        numericality: { only_integer: true,
                                        greater_than: 0,
                                        less_than_or_equal_to: 100 },
                        allow_nil: true
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

          def track
            rollout < 100 ? 'rollout' : 'stable'
          end

          def rollout
            value[:rollout].to_i.nonzero? || 100
          end

          def action
            value[:action] || 'start'
          end

          def on_stop
            value[:on_stop]
          end

          def value
            case @config
            when String then { name: @config, action: 'start' }
            when Hash then @config
            else {}
            end
          end
        end
      end
    end
  end
end
