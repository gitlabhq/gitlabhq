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

          ALLOWED_KEYS = %i[tag_name tag_message name description ref released_at milestones assets].freeze
          attributes %i[tag_name tag_message name ref milestones assets].freeze
          attr_reader :released_at

          def description
            config[:description]
          end

          entry :assets, Entry::Release::Assets, description: 'Release assets.'

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :tag_name, type: String, presence: true
            validates :tag_message, type: String, allow_blank: true
            validates :description, type: String, presence: true
            validates :milestones, array_of_strings_or_string: true, allow_blank: true
            validate do
              next unless config[:released_at]

              begin
                @released_at = DateTime.iso8601(config[:released_at])
              rescue ArgumentError
                errors.add(:released_at, "must be a valid datetime")
              end
            end
            validate do
              next unless config[:ref]
              next if Commit.reference_valid?(config[:ref])
              next if Gitlab::GitRefValidator.validate(config[:ref])

              errors.add(:ref, "must be a valid ref")
            end
          end

          def value
            @config[:assets] = assets_value if @config.key?(:assets)
            @config
          end
        end
      end
    end
  end
end
