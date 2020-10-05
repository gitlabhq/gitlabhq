# frozen_string_literal: true

module API
  module Entities
    class UnleashFeature < Grape::Entity
      expose :name
      expose :description, unless: ->(feature) { feature.description.nil? }
      expose :active, as: :enabled
      expose :strategies do |flag|
        flag.strategies.map do |strategy|
          if legacy_strategy?(strategy)
            UnleashLegacyStrategy.represent(strategy)
          elsif gitlab_user_list_strategy?(strategy)
            UnleashGitlabUserListStrategy.represent(strategy)
          else
            UnleashStrategy.represent(strategy)
          end
        end
      end

      private

      def legacy_strategy?(strategy)
        !strategy.respond_to?(:name)
      end

      def gitlab_user_list_strategy?(strategy)
        strategy.name == ::Operations::FeatureFlags::Strategy::STRATEGY_GITLABUSERLIST
      end
    end
  end
end
