# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a CI/CD Bridge job that is responsible for
        # defining a downstream project trigger.
        #
        class Bridge < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Processable

          ALLOWED_WHEN = %w[on_success on_failure always manual].freeze
          ALLOWED_KEYS = %i[trigger].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS + PROCESSABLE_ALLOWED_KEYS

            with_options allow_nil: true do
              validates :when, inclusion: {
                in: ALLOWED_WHEN,
                message: "should be one of: #{ALLOWED_WHEN.join(', ')}"
              }
            end

            validate on: :composed do
              unless trigger_defined? || bridge_needs.present?
                errors.add(:config, 'should contain either a trigger or a needs:pipeline')
              end
            end

            validate on: :composed do
              next unless bridge_needs.present?
              next if bridge_needs.one?

              errors.add(:config, 'should contain at most one bridge need')
            end
          end

          entry :trigger, ::Gitlab::Ci::Config::Entry::Trigger,
            description: 'CI/CD Bridge downstream trigger definition.',
            inherit: false

          entry :needs, ::Gitlab::Ci::Config::Entry::Needs,
            description: 'CI/CD Bridge needs dependency definition.',
            inherit: false,
            metadata: { allowed_needs: %i[job bridge] }

          attributes :when

          def self.matching?(name, config)
            !name.to_s.start_with?('.') &&
              config.is_a?(Hash) &&
              (config.key?(:trigger) || config.key?(:needs))
          end

          def self.visible?
            true
          end

          def value
            super.merge(
              trigger: (trigger_value if trigger_defined?),
              needs: (needs_value if needs_defined?),
              ignore: ignored?,
              when: self.when,
              scheduling_type: needs_defined? && !bridge_needs ? :dag : :stage
            ).compact
          end

          def bridge_needs
            needs_value[:bridge] if needs_value
          end
        end
      end
    end
  end
end
