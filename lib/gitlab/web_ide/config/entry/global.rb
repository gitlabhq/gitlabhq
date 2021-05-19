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

          def self.allowed_keys
            %i[terminal].freeze
          end

          validations do
            validates :config, allowed_keys: Global.allowed_keys
          end

          attributes allowed_keys

          entry :terminal, Entry::Terminal,
            description: 'Configuration of the webide terminal.'
        end
      end
    end
  end
end

::Gitlab::WebIde::Config::Entry::Global.prepend_mod_with('Gitlab::WebIde::Config::Entry::Global')
