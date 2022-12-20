# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a JWT definition.
        #
        class IdToken < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Config::Entry::Validatable

          attributes %i[aud]

          validations do
            validates :config, required_keys: %i[aud], allowed_keys: %i[aud]
            validates :aud, array_of_strings_or_string: true
          end

          def value
            { aud: aud }
          end
        end
      end
    end
  end
end
