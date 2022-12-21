# frozen_string_literal: true

module Types
  class Namespace::SharedRunnersSettingEnum < BaseEnum
    graphql_name 'SharedRunnersSetting'

    DEPRECATED_SETTINGS = [::Namespace::SR_DISABLED_WITH_OVERRIDE].freeze

    ::Namespace::SHARED_RUNNERS_SETTINGS.excluding(DEPRECATED_SETTINGS).each do |type|
      value type.upcase,
            description: "Sharing of runners is #{type.tr('_', ' ')}.",
            value: type
    end

    value ::Namespace::SR_DISABLED_WITH_OVERRIDE.upcase,
          description: "Sharing of runners is disabled and overridable.",
          value: ::Namespace::SR_DISABLED_WITH_OVERRIDE,
          deprecated: {
            reason: :renamed,
            replacement: ::Namespace::SR_DISABLED_AND_OVERRIDABLE,
            milestone: "17.0"
          }
  end
end
