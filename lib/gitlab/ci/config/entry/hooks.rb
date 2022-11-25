# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Hooks < ::Gitlab::Config::Entry::Node
          # `Configurable` alreadys adds `Validatable`
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_HOOKS = %i[pre_get_sources_script].freeze

          validations do
            validates :config, type: Hash, allowed_keys: ALLOWED_HOOKS
          end

          entry :pre_get_sources_script, Entry::Commands,
            description: 'Commands that will be executed on Runner before cloning/fetching the Git repository.'
        end
      end
    end
  end
end
