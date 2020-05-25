# frozen_string_literal: true

module Gitlab
  module WebIde
    class Config
      module Entry
        ##
        # This class represents a global entry - root Entry for entire
        # GitLab WebIde Configuration file.
        #
        class Global < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[terminal].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          entry :terminal, Entry::Terminal,
            description: 'Configuration of the webide terminal.'

          attributes :terminal
        end
      end
    end
  end
end
