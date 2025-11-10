# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class JobInput < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::BaseInput

          ALLOWED_KEYS = COMMON_ALLOWED_KEYS

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_KEYS

            validate do
              errors.add(:base, 'must have a default value') if config[:default].nil?
            end
          end
        end
      end
    end
  end
end
