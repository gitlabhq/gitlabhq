module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents an environment.
        #
        class Environment < Entry
          include Validatable

          ALLOWED_KEYS = %i[name url close]

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
                message: Gitlab::Regex.environment_name_regex_message }

            validates :name,
              format: {
                with: Gitlab::Regex.environment_name_regex,
                message: Gitlab::Regex.environment_name_regex_message }

            with_options if: :hash? do
              validates :config, allowed_keys: ALLOWED_KEYS

              validates :url,
                        length: { maximum: 255 },
                        addressable_url: true,
                        allow_nil: true

              validates :close, boolean: true, allow_nil: true
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

          def close
            value[:close]
          end

          def value
            case @config
            when String then { name: @config }
            when Hash then @config
            else {}
            end
          end
        end
      end
    end
  end
end
