# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of an Image Port.
        #
        class Port < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_KEYS = %i[number protocol name].freeze

          validations do
            validates :config, hash_or_integer: true
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :number, type: Integer, presence: true
            validates :protocol, type: String, inclusion: { in: %w[http https], message: 'should be http or https' }, allow_blank: true
            validates :name, type: String, presence: false, allow_nil: true
          end

          def number
            value[:number]
          end

          def protocol
            value[:protocol]
          end

          def name
            value[:name]
          end

          def value
            return { number: @config } if integer?
            return @config if hash?

            {}
          end
        end
      end
    end
  end
end
