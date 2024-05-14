# frozen_string_literal: true

module Types
  class Namespace::SharedRunnersSettingEnum < BaseEnum
    graphql_name 'SharedRunnersSetting'

    ::Namespace::SHARED_RUNNERS_SETTINGS.each do |type|
      value type.upcase,
        description: "Sharing of runners is #{type.tr('_', ' ')}.",
        value: type
    end
  end
end
