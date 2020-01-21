# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a release configuration.
        #
        class Release < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[tag_name name description assets].freeze
          attributes %i[tag_name name assets].freeze

          # Attributable description conflicts with
          # ::Gitlab::Config::Entry::Node.description
          def has_description?
            true
          end

          def description
            config[:description]
          end

          entry :assets, Entry::Release::Assets, description: 'Release assets.'

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :tag_name, presence: true
            validates :description, type: String, presence: true
          end

          helpers :assets

          def value
            @config[:assets] = assets_value if @config.key?(:assets)
            @config
          end
        end
      end
    end
  end
end
