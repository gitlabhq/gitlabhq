# frozen_string_literal: true

module API
  module Entities
    class UnleashGitlabUserListStrategy < Grape::Entity
      expose :name, documentation: { type: 'String' } do |_strategy|
        ::Operations::FeatureFlags::Strategy::STRATEGY_USERWITHID
      end
      expose :parameters, documentation: { type: 'Hash' } do |strategy|
        { userIds: strategy.user_list.user_xids }
      end
    end
  end
end
